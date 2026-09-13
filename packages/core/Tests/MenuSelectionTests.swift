import Foundation
import RationsCore
import Testing

struct MenuSelectionTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func excludesStaleUnknownAndDisabledReadings() {
        var preferences = DisplayPreferences()
        preferences.disabledProviders.insert(.grok)
        let accounts = [
            account(.codex, used: 100, age: 1200), account(.claude, used: 75),
            account(.antigravity, used: nil), account(.grok, used: 90)
        ]
        let selection = MenuSelection.tightest(in: accounts, preferences: preferences, now: now)
        #expect(selection?.account.profile.provider == .claude)
    }

    @Test
    func limitsSelectionToChosenProvider() {
        var preferences = DisplayPreferences()
        preferences.menuProvider = .antigravity
        let accounts = [account(.codex, used: 100), account(.antigravity, used: 20)]
        #expect(MenuSelection.tightest(in: accounts, preferences: preferences, now: now)?.window.usedPercent == 20)
    }

    @Test
    func allMissingReadingsProduceNoPercentage() {
        let accounts = [account(.codex, used: nil), account(.claude, used: 90, age: -60)]
        #expect(MenuSelection.tightest(in: accounts, preferences: DisplayPreferences(), now: now) == nil)
    }

    private func account(_ provider: ProviderID, used: Double?, age: Double = 60) -> AccountReading {
        AccountReading(
            profile: AccountProfile(id: provider.rawValue, provider: provider, name: "Test", plan: nil, email: nil),
            rows: [QuotaRow(id: "main", windows: [
                QuotaWindow(id: "weekly", label: "Weekly", usedPercent: used, resetsAt: nil)
            ])],
            fetchedAt: now.addingTimeInterval(-age)
        )
    }
}
