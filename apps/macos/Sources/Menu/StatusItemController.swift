import AppKit
import Observation
import RationsCore

@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let store: RationsStore
    private let showSettings: @MainActor () -> Void
    private var timer: Timer?

    init(store: RationsStore, showSettings: @escaping @MainActor () -> Void) {
        self.store = store
        self.showSettings = showSettings
        super.init()
        let menu = NSMenu()
        menu.delegate = self
        menu.autoenablesItems = false
        item.menu = menu
        observeChanges()
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        store.refreshIfNeeded()
        menu.removeAllItems()
        for provider in ProviderID.allCases where !store.preferences.disabledProviders.contains(provider) {
            addSection(provider, to: menu)
        }
        if menu.items.isEmpty {
            menu.addItem(NSMenuItem(title: "No providers enabled", action: nil, keyEquivalent: ""))
        }
        let refresh = MenuCommand(store.isRefreshing ? "Refreshing…" : "Refresh", key: "r") { [weak self] in
            self?.store.refresh()
        }
        refresh.isEnabled = !store.isRefreshing
        menu.addItem(refresh)
        menu.addItem(MenuCommand("Settings…", key: ",", handler: showSettings))
        menu.addItem(.separator())
        menu.addItem(MenuCommand("Quit Rations", key: "q") { NSApp.terminate(nil) })
    }

    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        for candidate in menu.items {
            (candidate.view as? AccountMenuItemView)?.setHighlighted(candidate === item)
        }
    }

    private func addSection(_ provider: ProviderID, to menu: NSMenu) {
        let accounts = store.accounts(for: provider)
        let newest = accounts.compactMap(\.fetchedAt).max()
        let title = provider.displayName + "   " + ResetText.age(of: newest, now: .now)
        let header = NSMenuItem.sectionHeader(title: title)
        menu.addItem(header)
        if accounts.isEmpty {
            let title = store.isRefreshing ? "Connecting…" : "Not connected"
            let empty = NSMenuItem(title: title, action: nil, keyEquivalent: "")
            empty.isEnabled = false
            empty.toolTip = store.providerErrors[provider]
            menu.addItem(empty)
            menu.addItem(MenuCommand("Open Sign-In…") { [weak self] in self?.store.signIn(provider) })
        }
        for account in accounts {
            menu.addItem(AccountMenuBuilder.item(account: account, store: store))
        }
        menu.addItem(.separator())
    }

    private func observeChanges() {
        withObservationTracking {
            updateLabel()
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeChanges() }
        }
    }

    private func updateLabel() {
        guard let button = item.button else { return }
        let aggregate = AggregateQuota.summarize(store.accounts, now: .now)
        button.image = StatusGlyph.image
        button.title = ""
        button.alphaValue = 1
        let text = aggregate.remainingPercent.map {
            "\(Int($0.rounded()))% remaining across \(aggregate.reportingAccountCount) accounts"
        }
            ?? "usage unavailable"
        let pending = aggregate.pendingAccountCount == 0
            ? "" : "; \(aggregate.pendingAccountCount) awaiting current usage"
        button.toolTip = "Rations · " + text + pending
        button.setAccessibilityLabel("Rations, " + text + pending)
        scheduleBoundaryUpdate(at: aggregate.nextUpdateAt)
    }

    private func scheduleBoundaryUpdate(at date: Date?) {
        timer?.invalidate()
        guard let date else { timer = nil; return }
        let nextTimer = Timer(timeInterval: max(0.1, date.timeIntervalSinceNow), repeats: false) { [weak self] _ in
            Task { @MainActor in self?.updateLabel() }
        }
        RunLoop.main.add(nextTimer, forMode: .common)
        timer = nextTimer
    }
}
