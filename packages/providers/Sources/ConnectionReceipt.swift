import RationsCore

public struct ConnectionReceipt: Sendable {
    public let state: LiveAccountState
    public let account: AccountProfile
    public let alreadyConnected: Bool
}
