import Foundation

public struct AccountReading: Identifiable, Codable, Equatable, Sendable {
    public var profile: AccountProfile
    public let rows: [QuotaRow]
    public var fetchedAt: Date?
    public let resetCredits: Int?
    public var error: String?
    public var notice: String?
    public var id: String { profile.id }

    public var menuRow: QuotaRow {
        if let main = rows.first(where: { $0.id == "main" }) { return main }
        let pools = rows.filter { !$0.isSupplemental }
        let windows = [QuotaPeriod.session, .weekly].compactMap { period in
            pools.compactMap { $0.window(for: period) }.max { ($0.usedPercent ?? -1) < ($1.usedPercent ?? -1) }
        }
        return QuotaRow(id: "summary", windows: windows)
    }

    public init(
        profile: AccountProfile, rows: [QuotaRow], fetchedAt: Date?, resetCredits: Int? = nil, error: String? = nil
    ) {
        self.profile = profile
        self.rows = rows
        self.fetchedAt = fetchedAt
        self.resetCredits = resetCredits
        self.error = error
    }

    public func isFresh(at now: Date) -> Bool {
        guard error == nil, let fetchedAt else { return false }
        let age = now.timeIntervalSince(fetchedAt)
        let resets = rows.filter { !$0.isSupplemental }.flatMap(\.windows).compactMap(\.resetsAt)
        return age >= 0 && age < 20 * 60 && !resets.contains(where: { $0 <= now })
    }
}
