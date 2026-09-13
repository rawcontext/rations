import Foundation
import RationsCore

enum ExternalSignInWatcher {
    static func run(
        _ provider: ProviderID, open: @escaping @Sendable () async throws -> Void,
        progress: @escaping @Sendable (SignInProgress) -> Void, reconnecting target: AccountProfile? = nil,
        captureCredentials: @escaping @Sendable (ProviderID, Bool) async throws -> AccountConnection = {
            try await CredentialDiscovery.capture($0, interactive: $1)
        }
    ) async throws -> AccountConnection {
        let previous = try await existingCredential(
            provider, interactive: target != nil, captureCredentials: captureCredentials
        )
        try Task.checkCancellation()
        if let previous, let target, previous.profile.id == target.id {
            progress(.connecting)
            return previous
        }
        try await open()
        progress(.waitingForBrowser(nil))
        let deadline = ContinuousClock.now + .seconds(300)
        var requestedAccess = false
        while ContinuousClock.now < deadline {
            try await Task.sleep(for: .seconds(1))
            if let account = try await capture(
                provider, requestedAccess: &requestedAccess, captureCredentials: captureCredentials
            ),
               account.credential != previous?.credential {
                try Task.checkCancellation()
                progress(.connecting)
                return account
            }
        }
        throw ProviderFailure.unavailable(
            "No new sign-in was detected. Finish signing in, or use the existing sign-in."
        )
    }

    private static func existingCredential(
        _ provider: ProviderID, interactive: Bool,
        captureCredentials: @Sendable (ProviderID, Bool) async throws -> AccountConnection
    ) async throws -> AccountConnection? {
        do {
            return try await captureCredentials(provider, interactive)
        } catch let error as ProviderFailure where interactive && error.needsKeychainApproval {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch { return nil }
    }

    private static func capture(
        _ provider: ProviderID, requestedAccess: inout Bool,
        captureCredentials: @Sendable (ProviderID, Bool) async throws -> AccountConnection
    ) async throws -> AccountConnection? {
        do {
            return try await captureCredentials(provider, false)
        } catch let error as ProviderFailure where error.needsKeychainApproval {
            guard !requestedAccess else { throw error }
            requestedAccess = true
            return try await captureCredentials(provider, true)
        } catch is CancellationError {
            throw CancellationError()
        } catch { return nil }
    }
}
