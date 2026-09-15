import AppKit
import Observation
import SwiftUI

@MainActor
final class SettingsWindowController: NSWindowController, NSToolbarDelegate {
    private let store: RationsStore
    private let settingsToolbar = NSToolbar(identifier: "RationsSettings")

    init(store: RationsStore) {
        self.store = store
        let content = RationsSettings(store: store, loginItem: LoginItemManager())
        let window = NSWindow(contentViewController: NSHostingController(rootView: content))
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 560, height: 450))
        window.isReleasedWhenClosed = false
        super.init(window: window)
        settingsToolbar.delegate = self
        settingsToolbar.displayMode = .iconOnly
        settingsToolbar.allowsUserCustomization = false
        window.toolbar = settingsToolbar
        window.toolbarStyle = .preference
        window.center()
        observeSelection()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Settings uses a SwiftUI hosting controller") }

    func show() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.flexibleSpace] + SettingsTab.allCases.map { NSToolbarItem.Identifier($0.rawValue) }
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        toolbarAllowedItemIdentifiers(toolbar) + [.flexibleSpace]
    }

    func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let tab = SettingsTab(rawValue: identifier.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = tab.title
        let view = NSHostingView(rootView: SettingsTabControl(tab: tab, store: store))
        view.frame = NSRect(x: 0, y: 0, width: 78, height: 58)
        item.view = view
        return item
    }

    private func observeSelection() {
        withObservationTracking {
            window?.title = store.selectedTab.title
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeSelection() }
        }
    }
}
