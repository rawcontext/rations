import RationsCore

struct NativeDiscoveryResult: Sendable {
    let provider: ProviderID
    let account: AccountConnection?
    let failure: ProviderFailure?

    static func capture(_ provider: ProviderID) async -> Self {
        do {
            return Self(provider: provider, account: try await CredentialDiscovery.capture(provider), failure: nil)
        } catch {
            let failure = error as? ProviderFailure ?? .unavailable(LiveAccountService.message(error))
            return Self(provider: provider, account: nil, failure: failure)
        }
    }
}
