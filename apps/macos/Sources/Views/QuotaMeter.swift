import RationsCore
import SwiftUI

struct QuotaMeter: View {
    let window: QuotaWindow?
    let preferences: DisplayPreferences
    var highlighted = false

    var body: some View {
        GeometryReader { geometry in
            if let window, let percent = preferences.usageMode.percent(for: window) {
                Capsule()
                    .fill(highlighted ? Color.white.opacity(0.28) : Color.primary.opacity(0.12))
                    .overlay(alignment: .leading) {
                        Capsule()
                            .fill(highlighted ? .white : preferences.tone(for: window).color)
                            .frame(width: geometry.size.width * percent / 100)
                    }
            } else {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: geometry.size.height / 2))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: geometry.size.height / 2))
                }
                .stroke(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}
