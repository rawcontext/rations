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
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 450))
        window.isReleasedWhenClosed = false
        super.init(window: window)
        settingsToolbar.delegate = self
        settingsToolbar.displayMode = .iconAndLabel
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

    func toolbarSelectableItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        SettingsTab.allCases.map { NSToolbarItem.Identifier($0.rawValue) }
    }

    func toolbar(
        _ toolbar: NSToolbar, itemForItemIdentifier identifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar flag: Bool
    ) -> NSToolbarItem? {
        guard let tab = SettingsTab(rawValue: identifier.rawValue) else { return nil }
        let item = NSToolbarItem(itemIdentifier: identifier)
        item.label = tab.title
        item.image = NSImage(systemSymbolName: tab.symbol, accessibilityDescription: tab.title)
        item.target = self
        item.action = #selector(selectTab)
        return item
    }

    @objc private func selectTab(_ sender: NSToolbarItem) {
        guard let tab = SettingsTab(rawValue: sender.itemIdentifier.rawValue) else { return }
        store.selectedTab = tab
    }

    private func observeSelection() {
        withObservationTracking {
            settingsToolbar.selectedItemIdentifier = NSToolbarItem.Identifier(store.selectedTab.rawValue)
            window?.title = store.selectedTab.title
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeSelection() }
        }
    }
}
