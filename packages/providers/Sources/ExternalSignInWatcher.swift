import Foundation
import RationsCore

enum ExternalSignInWatcher {
    static func run(
        _ provider: ProviderID, open: @escaping @Sendable () async throws -> Void,
        progress: @escaping @Sendable (SignInProgress) -> Void
    ) async throws -> AccountConnection {
        let previous = try? await CredentialDiscovery.capture(provider)
        try Task.checkCancellation()
        try await open()
        progress(.waitingForBrowser(nil))
        let deadline = ContinuousClock.now + .seconds(300)
        while ContinuousClock.now < deadline {
            try await Task.sleep(for: .seconds(1))
            if let account = try? await CredentialDiscovery.capture(provider),
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
}
