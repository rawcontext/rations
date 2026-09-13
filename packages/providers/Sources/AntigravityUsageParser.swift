import Foundation
import RationsCore

enum AntigravityUsageParser {
    static func parse(_ data: Data, profile: AccountProfile, now: Date) throws -> AccountReading {
        let root = try ProviderJSON(data)
        let payload = root.object("response") ?? root.object("summary") ?? root
        let rows = payload.objects("groups").enumerated().compactMap { index, group -> QuotaRow? in
            let windows = group.objects("buckets").compactMap(window)
            guard !windows.isEmpty else { return nil }
            let label = group.string("displayName") ?? "Quota group \(index + 1)"
            return QuotaRow(id: label, windows: windows, label: label)
        }
        guard !rows.isEmpty else { throw ProviderFailure.invalidResponse }
        return AccountReading(profile: profile, rows: rows, fetchedAt: now)
    }

    private static func window(_ object: ProviderJSON) -> QuotaWindow? {
        guard object.bool("disabled") != true, let id = object.string("bucketId") else { return nil }
        let fraction = object.number("remainingFraction") ?? object.object("remaining")?.number("remainingFraction")
        let used = fraction.flatMap { (0...1).contains($0) ? (1 - $0) * 100 : nil }
        let weekly = object.string("window") == "weekly" || id.hasSuffix("-weekly")
        return QuotaWindow(
            id: id, label: weekly ? "Weekly" : "5-hour", usedPercent: used,
            resetsAt: ProviderJSON.date(object.string("resetTime")), period: weekly ? .weekly : .session
        )
    }
}
