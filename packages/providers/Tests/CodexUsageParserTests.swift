import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct CodexUsageParserTests {
    @Test(arguments: [-1.0, 0.5, Double.greatestFiniteMagnitude])
    func invalidResetCountsStayUnknown(_ count: Double) throws {
        let data = try ProviderTestData.json([
            "account_id": "test-account", "rate_limit_reset_credits": ["available_count": count],
            "rate_limit": ["primary_window": ["used_percent": 25]]
        ])
        #expect(try parse(data).resetCredits == nil)
    }

    @Test
    func primaryWindowCanBeWeeklyAndModelsBelongToOneAccount() throws {
        let weekly: [String: Any] = ["used_percent": 42, "limit_window_seconds": 604_800, "reset_at": 1_800_060_000]
        let payload = try ProviderTestData.json([
            "account_id": "test-account", "plan_type": "pro",
            "rate_limit": ["primary_window": weekly],
            "rate_limit_reset_credits": ["available_count": 2],
            "additional_rate_limits": [["limit_name": "GPT-5.3", "rate_limit": ["secondary_window": weekly]]]
        ])
        let reading = try parse(payload)
        #expect(reading.rows.count == 2)
        #expect(reading.rows[1].label == "GPT-5.3")
        #expect(reading.menuRow.windows.first?.period == .weekly)
        #expect(reading.menuRow.windows.first?.remainingPercent == 58)
        #expect(reading.resetCredits == 2)
        #expect(reading.profile.plan == "Pro")
    }

    @Test
    func wrongAccountResponseIsRejected() throws {
        let data = try ProviderTestData.json(["account_id": "another-account"])
        #expect(throws: ProviderFailure.self) { try parse(data) }
    }

    @Test(arguments: [true as Any, 101, -1, "25", NSNull()])
    func malformedPercentStaysUnknown(_ value: Any) throws {
        let data = try ProviderTestData.json([
            "account_id": "test-account", "rate_limit": ["primary_window": ["used_percent": value]]
        ])
        #expect(try parse(data).menuRow.windows.first?.usedPercent == nil)
    }

    private func parse(_ data: Data) throws -> AccountReading {
        try CodexUsageParser.parse(data, profile: ProviderTestData.profile(.codex), now: ProviderTestData.now)
    }
}
