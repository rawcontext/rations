import Foundation
import RationsCore

enum CodexUsageParser {
    static func parse(_ data: Data, profile: AccountProfile, now: Date) throws -> AccountReading {
        let root = try ProviderJSON(data)
        guard let id = root.string("account_id") else { throw ProviderFailure.invalidResponse }
        let identity = AccountIdentity.profile(.codex, identity: id, plan: nil, email: nil)
        guard identity.id == profile.id else {
            throw ProviderFailure.unavailable("The Codex account changed. Reconnect it.")
        }
        let profile = AccountProfile(
            id: profile.id, provider: .codex, name: profile.name,
            plan: root.string("plan_type")?.capitalized ?? profile.plan, email: root.string("email") ?? profile.email
        )
        var rows: [QuotaRow] = []
        if let limits = root.object("rate_limit") { rows.append(row(limits, id: "main", label: nil)) }
        for extra in root.objects("additional_rate_limits") {
            guard let limits = extra.object("rate_limit") else { continue }
            let name = extra.string("limit_name") ?? extra.string("limit_id") ?? "Additional quota"
            rows.append(row(limits, id: name, label: name))
        }
        guard rows.contains(where: { !$0.windows.isEmpty }) else { throw ProviderFailure.invalidResponse }
        let count = root.object("rate_limit_reset_credits")?.number("available_count")
            .flatMap(Int.init(exactly:)).flatMap { $0 >= 0 ? $0 : nil }
        return AccountReading(profile: profile, rows: rows, fetchedAt: now, resetCredits: count)
    }

    private static func row(_ limits: ProviderJSON, id: String, label: String?) -> QuotaRow {
        let windows = ["primary_window", "secondary_window"].compactMap { key -> QuotaWindow? in
            guard let window = limits.object(key) else { return nil }
            let seconds = window.number("limit_window_seconds")
            let weekly = seconds.map { $0 >= 604_800 } ?? (key == "secondary_window")
            let name = weekly ? "Weekly" : durationLabel(seconds)
            return QuotaWindow(
                id: key, label: name, usedPercent: window.number("used_percent"),
                resetsAt: window.number("reset_at").map(Date.init(timeIntervalSince1970:)),
                period: weekly ? .weekly : .session
            )
        }
        return QuotaRow(id: id, windows: windows, label: label)
    }

    private static func durationLabel(_ seconds: Double?) -> String {
        guard let seconds, seconds > 0, let hours = Int(exactly: seconds / 3600) else { return "Session" }
        return "\(hours)-hour"
    }
}
