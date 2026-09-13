import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct AntigravityUsageParserTests {
    @Test
    func independentGroupsKeepTheirWindowsInsideOneAccount() throws {
        let reset = "2027-01-16T09:00:00Z"
        let data = try ProviderTestData.json(["groups": [
            ["displayName": "Google models", "buckets": [
                ["bucketId": "gemini-5h", "remainingFraction": 0.75, "resetTime": reset],
                ["bucketId": "gemini-weekly", "remainingFraction": 0.90, "resetTime": reset]
            ]],
            ["displayName": "Other models", "buckets": [
                ["bucketId": "3p-5h", "remaining": ["remainingFraction": 0.50], "resetTime": reset],
                ["bucketId": "3p-weekly", "remainingFraction": 0.80, "resetTime": reset],
                ["bucketId": "retired-weekly", "disabled": true, "remainingFraction": 0]
            ]]
        ]])
        let reading = try AntigravityUsageParser.parse(
            data, profile: ProviderTestData.profile(.antigravity), now: ProviderTestData.now
        )
        #expect(reading.rows.map(\.windows.count) == [2, 2])
        #expect(reading.menuRow.window(for: .session)?.usedPercent == 50)
        #expect(reading.menuRow.window(for: .weekly)?.usedPercent?.rounded() == 20)
        #expect(reading.rows[0].windows.first?.resetsAt == ProviderJSON.date(reset))
    }

    @Test
    func emptyQuotaIsNotReportedAsFull() throws {
        let data = try ProviderTestData.json(["groups": []])
        #expect(throws: ProviderFailure.self) {
            try AntigravityUsageParser.parse(data, profile: ProviderTestData.profile(.antigravity), now: .now)
        }
    }
}
