import RationsCore

struct NativeDiscoveryResult: Sendable {
    let provider: ProviderID
    let account: AccountConnection?
    let error: String?

    static func capture(_ provider: ProviderID) async -> Self {
        do {
            return Self(provider: provider, account: try await CredentialDiscovery.capture(provider), error: nil)
        } catch {
            return Self(provider: provider, account: nil, error: LiveAccountService.message(error))
        }
    }
}
