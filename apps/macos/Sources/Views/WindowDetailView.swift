import RationsCore
import SwiftUI

struct WindowDetailView: View {
    let window: QuotaWindow
    let preferences: DisplayPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(window.label)
                Spacer()
                Text(percentText).fontWeight(.semibold).foregroundStyle(preferences.tone(for: window).color)
            }
            .font(.system(size: 12))
            QuotaMeter(window: window, preferences: preferences)
            if preferences.resetMode != .relative {
                Text(ResetText.absolute(window.resetsAt)).font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if preferences.resetMode != .absolute {
                Text(ResetText.countdown(to: window.resetsAt, now: .now))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
        .monospacedDigit()
    }

    private var percentText: String {
        guard let percent = preferences.usageMode.percent(for: window) else { return "Usage unknown" }
        return "\(Int(percent.rounded()))% " + (preferences.usageMode == .remaining ? "left" : "used")
    }
}
