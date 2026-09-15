import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct CursorUsageParserTests {
    @Test
    func preservesFractionalPercentAndDoesNotDoubleCountModelBreakdowns() throws {
        let reading = try parse(CursorTestData.summary(individual: ["plan": [
            "totalPercentUsed": 0.25, "autoPercentUsed": 40, "apiPercentUsed": 60,
            "used": 100, "limit": 1000
        ]]))
        #expect(reading.menuRow.window(for: .monthly)?.usedPercent == 0.25)
        #expect(reading.rows.count == 3)
        #expect(reading.rows[1].windows.first?.label == "Cursor Models")
        #expect(reading.rows[2].windows.first?.label == "Other Models")
        #expect(reading.menuRow.resetWindow?.resetsAt == ProviderTestData.now.addingTimeInterval(3600))
        #expect(reading.profile.plan == "Ultra")
        #expect(reading.resetCredits == nil)
        #expect(AggregateQuota.summarize([reading], now: ProviderTestData.now).remainingPercent == 99.75)
    }

    @Test
    func usesModelPercentagesBeforeCentsWhenTotalIsAbsent() throws {
        let reading = try parse(CursorTestData.summary(individual: ["plan": [
            "autoPercentUsed": 20, "apiPercentUsed": 60, "used": 100, "limit": 1000
        ]]))
        #expect(reading.menuRow.tightestWindow?.usedPercent == 40)
    }

    @Test(arguments: ["plan", "overall", "pooled"])
    func supportsIndividualAndTeamAllowanceRatios(_ scope: String) throws {
        let allowance = ["used": 250, "limit": 1000]
        let data = try CursorTestData.summary(
            individual: scope == "pooled" ? [:] : [scope: allowance],
            team: scope == "pooled" ? [scope: allowance] : [:]
        )
        #expect(try parse(data).menuRow.tightestWindow?.usedPercent == 25)
    }

    @Test(arguments: ["null", "true", "\"20\"", "-1"])
    func invalidOrMissingAllowanceStaysUnknown(_ json: String) throws {
        let value = try JSONSerialization.jsonObject(with: Data(json.utf8), options: .fragmentsAllowed)
        let reading = try parse(CursorTestData.summary(individual: ["plan": ["totalPercentUsed": value]]))
        #expect(reading.menuRow.windows.first?.usedPercent == nil)
        #expect(reading.notice?.contains("did not report") == true)
        #expect(AggregateQuota.summarize([reading], now: ProviderTestData.now).remainingPercent == nil)
    }

    @Test
    func overageIsExhaustedAndExtraSpendDoesNotCountAsIncludedQuota() throws {
        let reading = try parse(CursorTestData.summary(individual: [
            "plan": ["totalPercentUsed": 150], "onDemand": ["enabled": true, "used": 250, "limit": 1000]
        ]))
        #expect(reading.menuRow.tightestWindow?.remainingPercent == 0)
        #expect(reading.rows.count == 1)
        #expect(reading.notice?.contains(2.5.formatted(.currency(code: "USD"))) == true)
        #expect(reading.notice?.contains(10.0.formatted(.currency(code: "USD"))) == true)
    }

    @Test
    func rejectsResponsesThatAreNotUsage() throws {
        let data = try ProviderTestData.json(["error": "authentication failed"])
        #expect(throws: ProviderFailure.self) { try parse(data) }
    }

    private func parse(_ data: Data) throws -> AccountReading {
        try CursorUsageParser.parse(data, profile: ProviderTestData.profile(.cursor), now: ProviderTestData.now)
    }
}
