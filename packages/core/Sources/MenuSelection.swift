import Foundation

public struct MenuSelection: Sendable {
    public let account: AccountReading
    public let window: QuotaWindow

    public static func tightest(
        in accounts: [AccountReading], preferences: DisplayPreferences, now: Date
    ) -> Self? {
        let candidates = accounts.filter {
            $0.isFresh(at: now)
                && !preferences.disabledProviders.contains($0.profile.provider)
                && (preferences.menuProvider == nil || preferences.menuProvider == $0.profile.provider)
        }.flatMap { account in
            account.rows.flatMap(\.windows).compactMap { window -> Self? in
                guard window.usedPercent != nil else { return nil }
                return Self(account: account, window: window)
            }
        }
        return candidates.sorted { left, right in
            if left.window.usedPercent != right.window.usedPercent {
                return (left.window.usedPercent ?? 0) > (right.window.usedPercent ?? 0)
            }
            let leftReset = left.window.resetsAt ?? .distantFuture
            let rightReset = right.window.resetsAt ?? .distantFuture
            if leftReset != rightReset { return leftReset < rightReset }
            return left.account.id + left.window.id < right.account.id + right.window.id
        }.first
    }
}
