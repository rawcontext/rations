import AppKit
import Sparkle

@MainActor
final class SoftwareUpdater {
    private let controller: SPUStandardUpdaterController?

    init() {
        if Bundle.main.bundleIdentifier == "com.rawcontext.rations",
           Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil {
            controller = SPUStandardUpdaterController(
                startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
            )
        } else {
            controller = nil
        }
    }

    func menuItem() -> NSMenuItem? {
        guard let controller else { return nil }
        let item = NSMenuItem(
            title: "Check for Updates…", action: #selector(SPUStandardUpdaterController.checkForUpdates(_:)),
            keyEquivalent: ""
        )
        item.target = controller
        item.isEnabled = controller.updater.canCheckForUpdates
        return item
    }
}
