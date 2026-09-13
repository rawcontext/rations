import AppKit
import RationsCore
import SwiftUI

@MainActor
enum AccountMenuBuilder {
    static func item(account: AccountReading, store: RationsStore) -> NSMenuItem {
        let item = NSMenuItem(title: account.profile.name, action: nil, keyEquivalent: "")
        item.view = AccountMenuItemView(content: AccountMenuRow(
            initialAccount: account, store: store
        ))
        item.submenu = detail(account: account, store: store)
        return item
    }

    private static func detail(account: AccountReading, store: RationsStore) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let detail = NSMenuItem()
        let host = NSHostingView(rootView: AccountDetailView(
            initialAccount: account, store: store
        ))
        host.setFrameSize(host.fittingSize)
        detail.view = host
        menu.addItem(detail)
        menu.addItem(.separator())
        let provider = account.profile.provider
        menu.addItem(MenuCommand("Open " + provider.displayName) { ProviderLinks.open(provider) })
        menu.addItem(MenuCommand("Reconnect Account") { store.reconnect(account.id) })
        menu.addItem(MenuCommand("Open Sign-In…") { store.signIn(provider) })
        return menu
    }
}
