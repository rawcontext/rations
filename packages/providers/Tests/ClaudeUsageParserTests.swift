import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct ClaudeUsageParserTests {
    @Test
    func sessionWithoutResetDoesNotBorrowTheWeeklyReset() throws {
        let screen = """
        Current session
        0% used
        Current week (all models)
        20% used
        Resets Sep 13 at 4pm (America/Chicago)
        """
        let now = try #require(ProviderJSON.date("2026-09-13T09:10:00Z"))
        let reading = try ClaudeTerminalParser.parse(screen, profile: ProviderTestData.profile(.claude), now: now)
        #expect(reading.menuRow.window(for: .session)?.resetsAt == nil)
        #expect(reading.menuRow.window(for: .weekly)?.resetsAt == ProviderJSON.date("2026-09-13T21:00:00Z"))
    }

    @Test
    func resetAcrossNewYearUsesTheNearestYear() throws {
        let now = try #require(ProviderJSON.date("2026-12-31T20:00:00Z"))
        let reset = ClaudeTerminalParser.resetDate("Resets Jan 1 at 4pm (America/Chicago)", now: now)
        #expect(reset == ProviderJSON.date("2027-01-01T22:00:00Z"))
    }

    @Test
    func importedIdentityComesFromAuthenticatedProfile() throws {
        let data = try ProviderTestData.json([
            "account": ["email_address": "imported@example.invalid"], "organization": ["uuid": "imported-org"]
        ])
        let profile = try ClaudeUsageParser.oauthProfile(data)
        #expect(profile.email == "imported@example.invalid")
        #expect(profile.id != ProviderTestData.profile(.claude).id)
        #expect(throws: ProviderFailure.self) { try ClaudeUsageParser.oauthProfile(Data("{}".utf8)) }
    }

    @Test
    func oauthUsagePreservesScopedWeeklyLimits() throws {
        let bucket: [String: Any] = ["utilization": 20, "resets_at": "2027-01-15T15:00:00.000Z"]
        let data = try ProviderTestData.json([
            "five_hour": bucket, "seven_day": bucket, "seven_day_sonnet": bucket, "seven_day_opus": NSNull()
        ])
        let reading = try ClaudeUsageParser.parse(
            data, profile: ProviderTestData.profile(.claude), now: ProviderTestData.now
        )
        #expect(reading.rows.count == 2)
        #expect(reading.rows[1].isSupplemental)
        #expect(reading.menuRow.windows.count == 2)
        #expect(reading.menuRow.window(for: .session)?.usedPercent == 20)
    }

    @Test
    func terminalUsageParsesBothWindowsAndLocalResetTimes() throws {
        let now = try #require(ProviderJSON.date("2026-09-13T09:10:00Z"))
        let screen = """
        Current session
        29% used
        Resets 5am (America/Chicago)
        Current week (all models)
        20% used
        Resets Sep 13 at 4pm (America/Chicago)
        """
        let reading = try ClaudeTerminalParser.parse(screen, profile: ProviderTestData.profile(.claude), now: now)
        #expect(reading.rows[0].windows.map(\.usedPercent) == [29, 20])
        #expect(reading.menuRow.window(for: .session)?.resetsAt == ProviderJSON.date("2026-09-13T10:00:00Z"))
        #expect(reading.menuRow.window(for: .weekly)?.resetsAt == ProviderJSON.date("2026-09-13T21:00:00Z"))
    }

    @Test
    func staleResetDoesNotBecomeNextYear() throws {
        let now = try #require(ProviderJSON.date("2026-09-13T22:00:00Z"))
        let reset = ClaudeTerminalParser.resetDate("Resets Sep 13 at 4pm (America/Chicago)", now: now)
        #expect(reset == ProviderJSON.date("2026-09-13T21:00:00Z"))
        #expect(ClaudeTerminalParser.resetDate("Resets 5am (America/Chicago)", now: now) == nil)
    }
}
