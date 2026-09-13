import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct GrokUsageParserTests {
    @Test
    func missingQuotaDoesNotBecomeZeroFromSpendCounters() throws {
        let data = try ProviderTestData.json(["config": [
            "currentPeriod": ["type": "USAGE_PERIOD_TYPE_WEEKLY", "end": "2027-01-16T09:00:00+00:00"],
            "onDemandUsed": ["val": 0], "onDemandCap": ["val": 0]
        ]])
        let reading = try parse(data)
        #expect(reading.menuRow.tightestWindow == nil)
        #expect(reading.menuRow.resetWindow?.resetsAt != nil)
        #expect(reading.notice != nil)
        #expect(reading.error == nil)
        #expect(reading.isFresh(at: ProviderTestData.now))
    }

    @Test
    func reportedQuotaIsUsedWhenAvailable() throws {
        let data = try ProviderTestData.json(["config": [
            "currentPeriod": ["type": "USAGE_PERIOD_TYPE_WEEKLY"], "creditUsagePercent": 32.5
        ]])
        let reading = try parse(data)
        #expect(reading.menuRow.windows.first?.remainingPercent == 67.5)
        #expect(reading.notice == nil)
    }

    private func parse(_ data: Data) throws -> AccountReading {
        try GrokUsageParser.parse(data, profile: ProviderTestData.profile(.grok), now: ProviderTestData.now)
    }
}
