import AppKit

@main
struct RationsApp {
    @MainActor static func main() {
        let application = NSApplication.shared
        let delegate = RationsAppDelegate()
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime(delegate) { application.run() }
    }
}
