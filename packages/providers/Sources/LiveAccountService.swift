import Foundation
import RationsCore

public actor LiveAccountService {
    private let vault = AccountVault()
    private let fetcher = ProviderFetcher()
    private var connections: [String: AccountConnection] = [:]
    private var active: [ProviderID: String] = [:]
    private var errors: [ProviderID: String] = [:]
    private var schedule = RefreshSchedule()
    private var activity = ProviderActivity()
    private var revision: UInt64 = 0
    private var restored = false

    public init() {}

    @preconcurrency public func signIn(
        _ provider: ProviderID, name: String,
        progress: @escaping @Sendable (SignInProgress) -> Void,
        openExternal: @escaping @Sendable () async throws -> Void, reconnecting accountID: String? = nil
    ) async throws -> ConnectionReceipt {
        try restore(interactive: true)
        let operation = activity.begin(provider)
        defer { activity.finish(provider, token: operation) }
        let target = try accountID.map { id in
            guard let saved = connections[id] else {
                throw ProviderFailure.unavailable("This account is no longer saved. Add it again to sign in.")
            }
            return saved.profile
        }
        let existingIDs = Set(connections.keys)
        let account = if provider == .antigravity {
            try await ExternalSignInWatcher.run(provider, open: openExternal, progress: progress, reconnecting: target)
        } else {
            try await ManagedSignIn.run(provider, progress: progress)
        }
        try ConnectionMerge.validate(account.profile, reconnecting: target)
        return try await finishConnection(
            account, name: name, alreadyConnected: existingIDs.contains(account.profile.id),
            isNative: provider != .codex
        )
    }

    public func state() throws -> LiveAccountState {
        try restore()
        return snapshot()
    }

    @preconcurrency public func refresh(
        enabled: Set<ProviderID>, onUpdate: (@Sendable (LiveAccountState) async -> Void)? = nil
    ) async -> LiveAccountState {
        do { try restore() } catch { return failureState(error) }
        let due = schedule.reserve(enabled.subtracting(activity.busy), now: .now)
        guard !due.isEmpty else { return snapshot() }
        let versions = activity.versions
        let blocked = await discover(due, versions: versions)
        await onUpdate?(snapshot())
        let accounts = connections.values.filter {
            let provider = $0.profile.provider
            return due.contains(provider) && !blocked.contains(provider)
                && activity.accepts(provider, version: versions[provider])
        }
        await withTaskGroup(of: AccountFetchResult.self) { group in
            for account in accounts {
                group.addTask { await AccountFetchResult.fetch(account, using: self.fetcher) }
            }
            for await result in group {
                guard let provider = connections[result.id]?.profile.provider,
                      activity.accepts(provider, version: versions[provider]) else { continue }
                accept(result)
                await onUpdate?(snapshot())
            }
        }
        return snapshot()
    }

    public func connect(_ provider: ProviderID, name: String, file: URL? = nil) async throws -> LiveAccountState {
        try restore(interactive: true)
        let operation = activity.begin(provider)
        defer { activity.finish(provider, token: operation) }
        let account = try await CredentialDiscovery.capture(provider, file: file, interactive: true)
        return try await finishConnection(
            account, name: name, alreadyConnected: connections[account.profile.id] != nil, isNative: file == nil
        ).state
    }

    private func finishConnection(
        _ incoming: AccountConnection, name: String, alreadyConnected: Bool, isNative: Bool
    ) async throws -> ConnectionReceipt {
        let id = incoming.profile.id
        let result = await AccountFetchResult.fetch(incoming, using: fetcher)
        try Task.checkCancellation()
        if let failure = result.failure, case .notSignedIn = failure { throw failure }
        let account = ConnectionMerge.prepare(
            incoming, existing: connections[id], requestedName: name, alreadyConnected: alreadyConnected
        )
        try vault.save(account, interactive: true)
        connections[id] = account
        if isNative { active[account.profile.provider] = id }
        errors[account.profile.provider] = nil
        accept(result)
        return ConnectionReceipt(
            state: snapshot(), account: connections[id]?.profile ?? account.profile, alreadyConnected: alreadyConnected
        )
    }

    public func rename(_ id: String, to name: String) throws -> LiveAccountState {
        try restore(interactive: true)
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, var account = connections[id] else { return snapshot() }
        account.profile.name = name
        account.lastReading?.profile.name = name
        try vault.save(account, interactive: true)
        connections[id] = account
        return snapshot()
    }

    public func remove(_ id: String) throws -> LiveAccountState {
        try restore(interactive: true)
        guard let account = connections[id], active[account.profile.provider] != id else {
            throw ProviderFailure.unavailable(
                "This is the active vendor sign-in. Switch accounts in the vendor tool first."
            )
        }
        try vault.remove(id)
        connections[id] = nil
        return snapshot()
    }

    private func restore(interactive: Bool = false) throws {
        guard !restored else { return }
        let accounts = try vault.load(interactive: interactive).map { ($0.profile.id, $0) }
        connections = Dictionary(accounts, uniquingKeysWith: { _, latest in latest })
        for id in connections.keys { connections[id]?.lastReading?.error = "Verifying the saved account…" }
        restored = true
    }

    private func discover(_ providers: Set<ProviderID>, versions: [ProviderID: UUID]) async -> Set<ProviderID> {
        var blocked: Set<ProviderID> = []
        await withTaskGroup(of: NativeDiscoveryResult.self) { group in
            for provider in providers { group.addTask { await NativeDiscoveryResult.capture(provider) } }
            for await result in group {
                guard activity.accepts(result.provider, version: versions[result.provider]) else { continue }
                if case .rateLimited = result.failure { blocked.insert(result.provider) }
                acceptDiscovery(result)
            }
        }
        return blocked
    }

    private func acceptDiscovery(_ result: NativeDiscoveryResult) {
        guard var account = result.account else {
            active[result.provider] = nil
            errors[result.provider] = result.error
            if case let .rateLimited(until) = result.failure { schedule.postpone(result.provider, until: until) }
            return
        }
        active[result.provider] = account.profile.id
        if let saved = connections[account.profile.id] {
            account.profile.name = saved.profile.name
            account.profile.plan = account.profile.plan ?? saved.profile.plan
            account.lastReading = saved.lastReading
        }
        connections[account.profile.id] = account
        errors[result.provider] = nil
        do { try vault.save(account) } catch { errors[result.provider] = Self.message(error) }
    }

    private func accept(_ result: AccountFetchResult) {
        guard var account = connections[result.id] else { return }
        if let reading = result.reading {
            let name = account.profile.name
            account.profile = reading.profile
            account.lastReading = reading
            account.profile.name = name
            account.lastReading?.profile.name = name
        } else {
            var reading = account.lastReading ?? emptyReading(account.profile)
            reading.error = result.failure.map(Self.message) ?? "Usage could not be refreshed."
            account.lastReading = reading
        }
        if case let .rateLimited(until) = result.failure { schedule.postpone(account.profile.provider, until: until) }
        connections[result.id] = account
        do { try vault.save(account) } catch { errors[account.profile.provider] = Self.message(error) }
    }

    private func snapshot() -> LiveAccountState {
        revision += 1
        let accounts = connections.values.map { account in
            account.lastReading ?? emptyReading(account.profile)
        }.sorted { $0.profile.name.localizedStandardCompare($1.profile.name) == .orderedAscending }
        return LiveAccountState(revision: revision, accounts: accounts, activeAccounts: active, providerErrors: errors)
    }

    private func emptyReading(_ profile: AccountProfile) -> AccountReading {
        AccountReading(profile: profile, rows: [QuotaRow(id: "main", windows: [])], fetchedAt: nil)
    }

    private func failureState(_ error: Error) -> LiveAccountState {
        for provider in ProviderID.allCases { errors[provider] = Self.message(error) }
        return snapshot()
    }

    nonisolated static func message(_ error: Error) -> String {
        (error as? ProviderFailure)?.errorDescription
            ?? "Couldn't reach the provider. Check your connection and try again."
    }
}
