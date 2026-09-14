import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct RefreshScheduleTests {
    @Test
    func automaticRefreshAndProviderCooldownShareOneSchedule() {
        var schedule = RefreshSchedule()
        let now = ProviderTestData.now
        #expect(schedule.reserve([.codex, .grok], now: now) == [.codex, .grok])
        #expect(schedule.reserve([.codex, .grok], now: now.addingTimeInterval(10)).isEmpty)
        schedule.postpone(.grok, until: now.addingTimeInterval(600))
        #expect(schedule.reserve([.codex, .grok], now: now.addingTimeInterval(60)) == [.codex])
        #expect(schedule.reserve([.grok], now: now.addingTimeInterval(600)) == [.grok])
    }

    @Test
    func manualRefreshImmediatelyRequestsNewUsageAndReschedulesPolling() {
        var schedule = RefreshSchedule()
        let now = ProviderTestData.now
        #expect(schedule.reserve([.codex], now: now) == [.codex])
        #expect(schedule.reserve([.codex], now: now.addingTimeInterval(10), manual: true) == [.codex])
        #expect(schedule.reserve([.codex], now: now.addingTimeInterval(60)).isEmpty)
        #expect(schedule.reserve([.codex], now: now.addingTimeInterval(70)) == [.codex])
    }

    @Test
    func manualRefreshStillRespectsProviderRetryAfter() {
        var schedule = RefreshSchedule()
        let now = ProviderTestData.now
        _ = schedule.reserve([.codex, .grok], now: now)
        schedule.postpone(.codex, until: now.addingTimeInterval(600))
        schedule.postpone(.codex, until: now.addingTimeInterval(120))
        #expect(schedule.reserve([.codex, .grok], now: now.addingTimeInterval(10), manual: true) == [.grok])
        #expect(schedule.reserve([.codex], now: now.addingTimeInterval(599), manual: true).isEmpty)
        #expect(schedule.reserve([.codex], now: now.addingTimeInterval(600), manual: true) == [.codex])
    }

    @Test
    func disabledProvidersNeverGetReserved() {
        var schedule = RefreshSchedule()
        #expect(schedule.reserve([], now: .now).isEmpty)
        #expect(schedule.reserve([], now: .now, manual: true).isEmpty)
        #expect(schedule.reserve([.claude], now: .now) == [.claude])
    }
}
