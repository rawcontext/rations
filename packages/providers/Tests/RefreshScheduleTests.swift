import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct RefreshScheduleTests {
    @Test
    func manualRefreshAndProviderCooldownShareOneSchedule() {
        var schedule = RefreshSchedule()
        let now = ProviderTestData.now
        #expect(schedule.reserve([.codex, .grok], now: now) == [.codex, .grok])
        #expect(schedule.reserve([.codex, .grok], now: now.addingTimeInterval(10)).isEmpty)
        schedule.postpone(.grok, until: now.addingTimeInterval(600))
        #expect(schedule.reserve([.codex, .grok], now: now.addingTimeInterval(60)) == [.codex])
        #expect(schedule.reserve([.grok], now: now.addingTimeInterval(600)) == [.grok])
    }

    @Test
    func disabledProvidersNeverGetReserved() {
        var schedule = RefreshSchedule()
        #expect(schedule.reserve([], now: .now).isEmpty)
        #expect(schedule.reserve([.claude], now: .now) == [.claude])
    }
}
