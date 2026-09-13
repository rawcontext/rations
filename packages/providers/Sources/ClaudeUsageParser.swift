import Foundation
import RationsCore

enum ClaudeUsageParser {
    static func oauthProfile(_ data: Data) throws -> AccountProfile {
        let root = try ProviderJSON(data)
        let account = root.object("account") ?? root
        let email = account.string("email_address") ?? account.string("emailAddress") ?? account.string("email")
        let organization = root.object("organization")?.string("uuid")
            ?? root.string("organization_uuid") ?? root.string("organizationUuid")
        guard let email, let organization else { throw ProviderFailure.invalidResponse }
        return AccountIdentity.profile(.claude, identity: organization + ":" + email, plan: nil, email: email)
    }

    static func profile(_ data: Data) throws -> AccountProfile {
        let status = try ProviderJSON(data)
        guard status.bool("loggedIn") == true, let email = status.string("email") else {
            throw ProviderFailure.notSignedIn("Run claude auth login, then connect the account.")
        }
        return AccountIdentity.profile(
            .claude, identity: (status.string("orgId") ?? "") + ":" + email,
            plan: status.string("subscriptionType")?.capitalized, email: email
        )
    }

    static func parse(_ data: Data, profile: AccountProfile, now: Date) throws -> AccountReading {
        let root = try ProviderJSON(data)
        let specs: [(String, QuotaPeriod)] = [("five_hour", .session), ("seven_day", .weekly)]
        let windows = specs.compactMap { key, period -> QuotaWindow? in
            guard let bucket = root.object(key) else { return nil }
            return window(bucket, id: key, label: period == .session ? "5-hour" : "Weekly", period: period)
        }
        guard !windows.isEmpty else { throw ProviderFailure.invalidResponse }
        var rows = [QuotaRow(id: "main", windows: windows)]
        for key in root.values.keys.sorted() where key.hasPrefix("seven_day_") {
            guard let bucket = root.object(key) else { continue }
            let label = String(key.dropFirst("seven_day_".count)).replacingOccurrences(of: "_", with: " ").capitalized
            rows.append(QuotaRow(
                id: key, windows: [window(bucket, id: key, label: "Weekly", period: .weekly)],
                label: "↳ " + label, isSupplemental: true
            ))
        }
        return AccountReading(profile: profile, rows: rows, fetchedAt: now)
    }

    private static func window(_ value: ProviderJSON, id: String, label: String, period: QuotaPeriod) -> QuotaWindow {
        QuotaWindow(
            id: id, label: label, usedPercent: value.number("utilization"),
            resetsAt: ProviderJSON.date(value.string("resets_at")), period: period
        )
    }
}
