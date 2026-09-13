import Foundation
import RationsCore
import Testing

struct ResetTextTests {
    @Test(arguments: [(-60.0, "Reset due"), (0, "Reset due"), (30, "<1m"), (60, "1m"),
                      (3600, "1h 0m"), (8040, "2h 14m"), (86400, "1d 0h"), (223200, "2d 14h")])
    func handlesCountdownBoundaries(seconds: Double, expected: String) {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(ResetText.countdown(to: now.addingTimeInterval(seconds), now: now) == expected)
    }

    @Test
    func missingResetIsNotInferred() {
        #expect(ResetText.countdown(to: nil, now: .now) == "Unknown")
        #expect(ResetText.absolute(nil) == "Reset time unknown")
    }

    @Test
    func localTimeUsesSuppliedTimeZone() throws {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let chicago = try #require(TimeZone(identifier: "America/Chicago"))
        #expect(ResetText.absolute(date, timeZone: utc) != ResetText.absolute(date, timeZone: chicago))
    }
}
