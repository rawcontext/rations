import SwiftUI

@main
struct RationsApp: App {
    var body: some Scene {
        MenuBarExtra("Rations", systemImage: "gauge.with.dots.needle.33percent") {
            RationsPopover()
        }
        .menuBarExtraStyle(.window)

        Settings {
            RationsSettings()
        }
    }
}
