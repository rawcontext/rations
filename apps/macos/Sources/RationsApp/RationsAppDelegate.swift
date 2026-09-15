import AppKit
import Observation
import RationsProviders

@MainActor
final class RationsAppDelegate: NSObject, NSApplicationDelegate {
    private let store = RationsStore()
    private var settings: SettingsWindowController?
    private var status: StatusItemController?
    private var instanceLock: AppInstanceLock?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard claimInstance() else { NSApp.terminate(nil); return }
        let settings = SettingsWindowController(store: store)
        self.settings = settings
        status = StatusItemController(store: store) { [weak settings] in settings?.show() }
        NSApp.mainMenu = ApplicationMenu.make { [weak settings] in settings?.show() }
        if CommandLine.arguments.contains("--settings") { settings.show() }
        observeMessages()
        store.start()
    }

    func applicationWillTerminate(_ notification: Notification) { ProviderProcesses.shared.stopAll() }

    private func claimInstance() -> Bool {
        let identifier = Bundle.main.bundleIdentifier ?? "com.rawcontext.rations.dev"
        let file = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Rations/Instances/\(identifier).lock")
        do {
            instanceLock = try AppInstanceLock.claim(at: file)
            return instanceLock != nil
        } catch {
            NSApp.presentError(error)
            return false
        }
    }

    private func observeMessages() {
        withObservationTracking {
            if store.message != nil || store.addingProvider != nil { settings?.show() }
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeMessages() }
        }
    }
}
