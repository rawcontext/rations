import Foundation

public struct AggregateQuota: Sendable {
    public let remainingPercent: Double?
    public let reportingAccountCount: Int
    public let totalAccountCount: Int
    public let nextUpdateAt: Date?

    public var pendingAccountCount: Int { totalAccountCount - reportingAccountCount }

    public static func summarize(_ readings: [AccountReading], now: Date) -> Self {
        let accounts = latestAccounts(readings)
        let available = accounts.compactMap { remaining(for: $0, now: now) }
        return Self(
            remainingPercent: available.isEmpty ? nil : available.reduce(0, +) / Double(available.count),
            reportingAccountCount: available.count,
            totalAccountCount: accounts.count,
            nextUpdateAt: nextBoundary(in: accounts, now: now)
        )
    }

    private static func remaining(for account: AccountReading, now: Date) -> Double? {
        guard account.isFresh(at: now) else { return nil }
        let pools = account.rows.filter { !$0.isSupplemental }
        guard !pools.isEmpty else { return nil }
        let available = pools.compactMap { pool -> Double? in
            guard !pool.windows.isEmpty else { return nil }
            let values = pool.windows.compactMap { window -> Double? in
                if let reset = window.resetsAt, reset <= now { return nil }
                return window.remainingPercent
            }
            guard values.count == pool.windows.count else { return nil }
            return values.min()
        }
        guard available.count == pools.count else { return nil }
        return available.reduce(0, +) / Double(available.count)
    }

    private static func latestAccounts(_ readings: [AccountReading]) -> [AccountReading] {
        let grouped = Dictionary(grouping: readings) { $0.profile.provider.rawValue + ":" + $0.id }
        return grouped.values.compactMap { group in
            group.max { ($0.fetchedAt ?? .distantPast) < ($1.fetchedAt ?? .distantPast) }
        }
    }

    private static func nextBoundary(in accounts: [AccountReading], now: Date) -> Date? {
        accounts.flatMap { account in
            let freshness = account.fetchedAt.map { [$0.addingTimeInterval(20 * 60)] } ?? []
            return freshness + account.rows.flatMap(\.windows).compactMap(\.resetsAt)
        }.filter { $0 > now }.min()
    }
}
