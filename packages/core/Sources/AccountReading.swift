import Foundation

public struct AccountReading: Identifiable, Equatable, Sendable {
    public var profile: AccountProfile
    public let rows: [QuotaRow]
    public var fetchedAt: Date?
    public let resetCredits: Int?
    public var id: String { profile.id }

    public init(profile: AccountProfile, rows: [QuotaRow], fetchedAt: Date?, resetCredits: Int? = nil) {
        self.profile = profile
        self.rows = rows
        self.fetchedAt = fetchedAt
        self.resetCredits = resetCredits
    }

    public func isFresh(at now: Date) -> Bool {
        guard let fetchedAt else { return false }
        let age = now.timeIntervalSince(fetchedAt)
        return age >= 0 && age < 20 * 60
    }
}
