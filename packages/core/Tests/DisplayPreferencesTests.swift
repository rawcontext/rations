import RationsCore
import Testing

struct DisplayPreferencesTests {
    @Test
    func refreshDefaultsToFifteenMinutes() {
        #expect(DisplayPreferences().refreshMinutes == 15)
    }

    @Test(arguments: [(0.0, UsageTone.comfortable), (75.0, .warning), (90.0, .critical), (100.0, .critical)])
    func pressureUsesRemainingQuota(used: Double, tone: UsageTone) {
        var preferences = DisplayPreferences()
        let window = QuotaWindow(id: "weekly", label: "Weekly", usedPercent: used, resetsAt: nil)
        #expect(preferences.tone(for: window) == tone)
        preferences.usageMode = .used
        #expect(preferences.tone(for: window) == tone)
    }

    @Test
    func restoresValidPreferenceBounds() {
        var preferences = DisplayPreferences()
        preferences.criticalRemaining = 150
        preferences.warningRemaining = -5
        preferences.refreshMinutes = 0
        preferences.normalize()
        #expect(preferences.criticalRemaining == 99)
        #expect(preferences.warningRemaining == 100)
        #expect(preferences.refreshMinutes == 2)
    }
}
