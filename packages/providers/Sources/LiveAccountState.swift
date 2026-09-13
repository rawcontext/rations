import RationsCore

public struct LiveAccountState: Sendable {
    public let accounts: [AccountReading]
    public let activeAccounts: [ProviderID: String]
    public let providerErrors: [ProviderID: String]
}
