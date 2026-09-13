import Foundation
import RationsCore

enum GrokUsageParser {
    static func parse(_ data: Data, profile: AccountProfile, now: Date) throws -> AccountReading {
        let root = try ProviderJSON(data)
        guard let config = root.object("config"), let period = config.object("currentPeriod") else {
            throw ProviderFailure.invalidResponse
        }
        let type = period.string("type") ?? ""
        let label = type.contains("WEEKLY") ? "Weekly" : "Included quota"
        let reset = ProviderJSON.date(period.string("end"))
        let percent = config.number("creditUsagePercent")
        let window = QuotaWindow(id: "included", label: label, usedPercent: percent, resetsAt: reset)
        var reading = AccountReading(
            profile: profile, rows: [QuotaRow(id: "main", windows: [window])], fetchedAt: now
        )
        if window.usedPercent == nil {
            reading.notice = "Grok did not expose a usage percentage."
            if reset != nil { reading.notice?.append(" The reset date is available.") }
        }
        return reading
    }
}
