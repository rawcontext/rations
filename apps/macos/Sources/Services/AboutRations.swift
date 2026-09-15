import AppKit
import SwiftUI

@MainActor
enum AboutRations {
    private static var window: NSWindow?

    static func show() {
        if window == nil {
            let created = NSWindow(contentViewController: NSHostingController(rootView: AboutView()))
            created.title = "About Rations"
            created.styleMask = [.titled, .closable]
            created.isReleasedWhenClosed = false
            created.center()
            window = created
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
