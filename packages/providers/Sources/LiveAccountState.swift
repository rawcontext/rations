import RationsCore

public struct LiveAccountState: Sendable {
    public let revision: UInt64
    public let accounts: [AccountReading]
    public let activeAccounts: [ProviderID: String]
    public let providerErrors: [ProviderID: String]
}
