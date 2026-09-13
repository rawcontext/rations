import Foundation

public struct ProviderSnapshot: Equatable, Sendable {
    public let provider: ProviderID
    public let windows: [QuotaWindow]
    public let fetchedAt: Date

    public init(provider: ProviderID, windows: [QuotaWindow], fetchedAt: Date) {
        self.provider = provider
        self.windows = windows
        self.fetchedAt = fetchedAt
    }
}
