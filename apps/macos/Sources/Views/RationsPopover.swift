import AppKit
import SwiftUI

struct RationsPopover: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rations")
                .font(.headline)

            ContentUnavailableView(
                "No accounts connected",
                systemImage: "gauge.with.dots.needle.0percent",
                description: Text("Your subscription usage and reset times will appear here.")
            )

            Divider()
            HStack {
                SettingsLink()
                Spacer()
                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .keyboardShortcut("q")
            }
        }
        .padding()
        .frame(width: 360)
    }
}
