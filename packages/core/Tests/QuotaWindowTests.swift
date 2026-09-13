import Foundation
import RationsCore
import Testing

struct QuotaWindowTests {
    @Test(arguments: [0.0, 25.5, 75.0, 100.0])
    func preservesKnownUsage(used: Double) {
        let window = makeWindow(used: used)
        #expect(window.usedPercent == used)
        #expect(window.remainingPercent == 100 - used)
        #expect(window.resetsAt == Date(timeIntervalSince1970: 1_800_000_000))
    }

    @Test(arguments: [-1.0, 101.0, Double.nan, .infinity, -.infinity])
    func invalidUsageStaysUnknown(used: Double) {
        #expect(makeWindow(used: used).usedPercent == nil)
    }

    @Test
    func missingUsageDoesNotBecomeZero() {
        let window = makeWindow(used: nil)
        #expect(window.remainingPercent == nil)
        #expect(window.resetsAt != nil)
    }

    private func makeWindow(used: Double?) -> QuotaWindow {
        QuotaWindow(
            id: "session",
            label: "5-hour",
            usedPercent: used,
            resetsAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
    }
}
