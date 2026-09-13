import Foundation
import Observation
import RationsCore
import RationsProviders

@MainActor @Observable
final class RationsStore {
    var preferences: DisplayPreferences { didSet { persistPreferences(); scheduleRefresh() } }
    private(set) var accounts: [AccountReading] = []
    private(set) var activeAccounts: [ProviderID: String] = [:]
    private(set) var providerErrors: [ProviderID: String] = [:]
    private(set) var isRefreshing = false
    var selectedTab = SettingsTab.general
    var addingProvider: ProviderID?
    var reconnectingAccount: AccountProfile?
    var automaticallyStartSignIn = false
    var connectionNotice: String?
    var message: String?
    private let service = LiveAccountService()
    private var refreshTimer: Timer?
    private var lastRefresh = Date.distantPast

    init() {
        let saved = UserDefaults.standard.data(forKey: "displayPreferences")
        var preferences = saved.flatMap { try? JSONDecoder().decode(DisplayPreferences.self, from: $0) }
            ?? DisplayPreferences()
        preferences.normalize()
        self.preferences = preferences
    }

    func start() {
        Task {
            do { apply(try await service.state()) } catch { message = error.localizedDescription }
            await refreshNow()
        }
        scheduleRefresh()
    }

    func updatePreferences(_ update: (inout DisplayPreferences) -> Void) {
        var value = preferences
        update(&value)
        value.normalize()
        preferences = value
    }

    func refresh() { Task { await refreshNow() } }

    func refreshIfNeeded() {
        if Date.now.timeIntervalSince(lastRefresh) >= 60 { refresh() }
    }

    func connect(_ provider: ProviderID, name: String, file: URL? = nil) async throws {
        apply(try await service.connect(provider, name: name, file: file))
    }

    func rename(_ accountID: String, to name: String) {
        Task {
            do { apply(try await service.rename(accountID, to: name)) } catch { message = error.localizedDescription }
        }
    }

    func remove(_ accountID: String) {
        Task {
            do { apply(try await service.remove(accountID)) } catch { message = error.localizedDescription }
        }
    }

    func reconnect(_ accountID: String) {
        guard let account = accounts.first(where: { $0.id == accountID }) else { return }
        signIn(account.profile.provider)
        reconnectingAccount = account.profile
    }

    func signIn(_ provider: ProviderID, startImmediately: Bool = true) {
        connectionNotice = nil
        reconnectingAccount = nil
        selectedTab = .accounts
        automaticallyStartSignIn = startImmediately
        addingProvider = provider
    }

    func completeSignIn(
        _ provider: ProviderID, name: String, progress: @escaping @Sendable (SignInProgress) -> Void,
        reconnecting accountID: String? = nil
    ) async throws {
        let receipt = try await service.signIn(
            provider, name: name, progress: progress,
            openExternal: { try await ProviderSignIn.open(provider) }, reconnecting: accountID
        )
        apply(receipt.state)
        connectionNotice = receipt.alreadyConnected
            ? "\(receipt.account.name) is already connected. Its sign-in has been refreshed."
            : "\(receipt.account.name) connected."
    }

    func isActive(_ account: AccountReading) -> Bool { activeAccounts[account.profile.provider] == account.id }
    func accounts(for provider: ProviderID) -> [AccountReading] { accounts.filter { $0.profile.provider == provider } }

    private func refreshNow() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        let enabled = Set(ProviderID.allCases).subtracting(preferences.disabledProviders)
        apply(await service.refresh(enabled: enabled))
        lastRefresh = .now
        isRefreshing = false
    }

    private func apply(_ state: LiveAccountState) {
        accounts = state.accounts
        activeAccounts = state.activeAccounts
        providerErrors = state.providerErrors
        ConnectionDiagnostics.writeIfRequested(state)
    }

    private func scheduleRefresh() {
        refreshTimer?.invalidate()
        let timer = Timer(timeInterval: Double(preferences.refreshMinutes) * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        RunLoop.main.add(timer, forMode: .common)
        refreshTimer = timer
    }

    private func persistPreferences() {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        UserDefaults.standard.set(data, forKey: "displayPreferences")
    }
}
