import Foundation

public enum ResetText {
    public static func countdown(to reset: Date?, now: Date) -> String {
        guard let reset else { return "Unknown" }
        let seconds = reset.timeIntervalSince(now)
        guard seconds > 0 else { return "Reset due" }
        if seconds < 60 { return "<1m" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes)m" }
        let hours = minutes / 60
        if hours < 24 { return "\(hours)h \(minutes % 60)m" }
        return "\(hours / 24)d \(hours % 24)h"
    }

    public static func absolute(_ reset: Date?, timeZone: TimeZone = .current) -> String {
        guard let reset else { return "Reset time unknown" }
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM jmm z")
        return "Resets " + formatter.string(from: reset)
    }

    public static func age(of fetchedAt: Date?, now: Date) -> String {
        guard let fetchedAt else { return "Not connected" }
        let seconds = max(0, now.timeIntervalSince(fetchedAt))
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        return "\(Int(seconds / 3600))h ago"
    }
}
