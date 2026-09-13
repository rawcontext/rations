import Foundation
import RationsCore

enum ClaudeTerminalParser {
    static func parse(_ text: String, profile: AccountProfile, now: Date) throws -> AccountReading {
        let specs: [(String, QuotaPeriod)] = [("current session", .session), ("current week (all models)", .weekly)]
        let windows = specs.compactMap { marker, period -> QuotaWindow? in
            guard let tail = section(text, after: marker) else { return nil }
            guard let regex = try? NSRegularExpression(pattern: #"(\d+(?:\.\d+)?)%\s*used"#),
                  let match = regex.firstMatch(in: tail, range: NSRange(tail.startIndex..., in: tail)),
                  let range = Range(match.range(at: 1), in: tail), let used = Double(tail[range]) else { return nil }
            let resetLine = tail.components(separatedBy: .newlines).first {
                $0.localizedCaseInsensitiveContains("resets")
            }
            return QuotaWindow(
                id: period.rawValue, label: period == .session ? "5-hour" : "Weekly", usedPercent: used,
                resetsAt: resetLine.flatMap { resetDate($0, now: now) }, period: period
            )
        }
        guard windows.count == 2 else { throw ProviderFailure.invalidResponse }
        return AccountReading(profile: profile, rows: [QuotaRow(id: "main", windows: windows)], fetchedAt: now)
    }

    private static func section(_ text: String, after marker: String) -> String? {
        guard let heading = text.range(of: marker, options: .caseInsensitive) else { return nil }
        let tail = String(text[heading.upperBound...])
        let next = tail.range(of: #"(?im)^\s*Current (?:session|week)\b"#, options: .regularExpression)
        return next.map { String(tail[..<$0.lowerBound]) } ?? tail
    }

    static func resetDate(_ line: String, now: Date) -> Date? {
        guard let range = line.range(of: "Resets", options: .caseInsensitive) else { return nil }
        var value = String(line[range.upperBound...]).trimmingCharacters(in: .whitespaces)
        var zone = TimeZone.current
        if let start = value.lastIndex(of: "("), let end = value.lastIndex(of: ")"), start < end {
            zone = TimeZone(identifier: String(value[value.index(after: start)..<end])) ?? zone
            value = String(value[..<start]).trimmingCharacters(in: .whitespaces)
        }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = zone
        formatter.defaultDate = calendar.startOfDay(for: now)
        for format in ["MMM d 'at' ha", "MMM d 'at' h:mma", "ha", "h:mma"] {
            formatter.dateFormat = format
            guard var date = formatter.date(from: value) else { continue }
            if format.hasPrefix("MMM") { return monthDayReset(date, now: now, calendar: calendar) }
            if !format.hasPrefix("MMM"), date <= now {
                date = calendar.date(byAdding: .day, value: 1, to: date) ?? date
            }
            if !format.hasPrefix("MMM"), date.timeIntervalSince(now) > 6 * 3600 { return nil }
            return date
        }
        return nil
    }

    private static func monthDayReset(_ date: Date, now: Date, calendar: Calendar) -> Date? {
        let candidates = [-1, 0, 1].compactMap { calendar.date(byAdding: .year, value: $0, to: date) }
        guard let closest = candidates.min(by: {
            abs($0.timeIntervalSince(now)) < abs($1.timeIntervalSince(now))
        }), abs(closest.timeIntervalSince(now)) <= 8 * 86400 else { return nil }
        return closest
    }
}
