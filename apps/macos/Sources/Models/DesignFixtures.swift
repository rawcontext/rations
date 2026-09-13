import Foundation
import RationsCore

enum DesignFixtures {
    static func accounts(now: Date) -> [AccountReading] {
        codexAccounts(now: now) + [
            claude(details: ("Personal", "Max 5x"), remaining: (22, 59), opus: 77, now: now),
            claude(details: ("Acme", "Team"), remaining: (80, 45), opus: 92, now: now),
            antigravity(now: now), grok(now: now)
        ]
    }

    private static func codexAccounts(now: Date) -> [AccountReading] {
        let accounts: [AccountPreviewSpec] = [
            .init(name: "Lab", plan: "Pro", remaining: 38, credits: 2),
            .init(name: "Acme", plan: "Team", remaining: 18, credits: 0),
            .init(name: "Northwind", plan: "Plus", remaining: 52, credits: 0),
            .init(name: "Personal", plan: "Plus", remaining: 73, credits: 1)
        ]
        return accounts.enumerated().map { index, item in
            let weekly = window(.weekly, left: item.remaining, seconds: Double(index + 1) * 110_000, now: now)
            let windows = index == 0 ? [window(.session, left: 0, seconds: 8040, now: now), weekly] : [weekly]
            return reading(.codex, details: (item.name, item.plan), now: now, rows: [
                QuotaRow(id: "main", windows: windows)
            ], credits: item.credits)
        }
    }

    private static func claude(
        details: (String, String), remaining: (session: Double, weekly: Double), opus: Double, now: Date
    ) -> AccountReading {
        reading(.claude, details: details, now: now, rows: [
            QuotaRow(id: "main", windows: [
                window(.session, left: remaining.session, seconds: 10_140, now: now),
                window(.weekly, left: remaining.weekly, seconds: 118_800, now: now)
            ]),
            QuotaRow(id: "opus", windows: [
                window(.weekly, left: opus, seconds: 118_800, now: now)
            ], label: "↳ Opus", isSupplemental: true)
        ])
    }

    private static func antigravity(now: Date) -> AccountReading {
        let groups: [(name: String, remaining: (session: Double, weekly: Double))] = [
            ("Claude & GPT", (46, 12)), ("Gemini", (88, 65))
        ]
        return reading(.antigravity, details: ("Personal", "Pro"), now: now, rows: groups.map { group in
            QuotaRow(id: group.name, windows: [
                window(.session, left: group.remaining.session, seconds: 12_540, now: now),
                window(.weekly, left: group.remaining.weekly, seconds: 223_200, now: now)
            ], label: group.name)
        })
    }

    private static func grok(now: Date) -> AccountReading {
        reading(.grok, details: ("Personal", "SuperGrok"), now: now, rows: [
            QuotaRow(id: "main", windows: [window(.weekly, left: 81, seconds: 432_000, now: now)])
        ])
    }

    private static func window(_ period: QuotaPeriod, left: Double, seconds: Double, now: Date) -> QuotaWindow {
        QuotaWindow(
            id: period == .session ? "session" : "weekly",
            label: period == .session ? "5-hour" : "Weekly",
            usedPercent: 100 - left,
            resetsAt: now.addingTimeInterval(seconds),
            period: period
        )
    }

    private static func reading(
        _ provider: ProviderID, details: (name: String, plan: String), now: Date, rows: [QuotaRow], credits: Int? = nil
    ) -> AccountReading {
        AccountReading(
            profile: AccountProfile(
                id: provider.rawValue + "-" + details.name.lowercased(), provider: provider,
                name: details.name, plan: details.plan, email: "preview@example.com"
            ),
            rows: rows, fetchedAt: now.addingTimeInterval(-120), resetCredits: credits
        )
    }
}
