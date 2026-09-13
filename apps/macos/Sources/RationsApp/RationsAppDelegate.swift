import AppKit
import Observation
import RationsProviders

@MainActor
final class RationsAppDelegate: NSObject, NSApplicationDelegate {
    private let store = RationsStore()
    private var settings: SettingsWindowController?
    private var status: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let settings = SettingsWindowController(store: store)
        self.settings = settings
        status = StatusItemController(store: store) { [weak settings] in settings?.show() }
        NSApp.mainMenu = ApplicationMenu.make()
        if CommandLine.arguments.contains("--settings") { settings.show() }
        observeMessages()
        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) { ProviderProcesses.shared.stopAll() }

    private func observeMessages() {
        withObservationTracking {
            if store.message != nil { settings?.show() }
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeMessages() }
        }
    }
}
