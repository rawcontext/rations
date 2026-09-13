import AppKit
import RationsCore
import SwiftUI

@MainActor
enum AccountMenuBuilder {
    static func item(account: AccountReading, row: QuotaRow, store: RationsStore) -> NSMenuItem {
        let title = row.label ?? account.profile.name
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.view = AccountMenuItemView(content: AccountMenuRow(
            account: account, row: row, preferences: store.preferences, active: store.isActive(account)
        ))
        item.isEnabled = !row.isSupplemental
        if !row.isSupplemental { item.submenu = detail(account: account, row: row, store: store) }
        return item
    }

    private static func detail(account: AccountReading, row: QuotaRow, store: RationsStore) -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false
        let detail = NSMenuItem()
        let host = NSHostingView(rootView: AccountDetailView(
            account: account, row: row, preferences: store.preferences
        ))
        host.setFrameSize(host.fittingSize)
        detail.view = host
        menu.addItem(detail)
        menu.addItem(.separator())
        let provider = account.profile.provider
        menu.addItem(MenuCommand("Open " + provider.displayName) { ProviderLinks.open(provider) })
        if !store.isActive(account) {
            let command = MenuCommand("Use " + account.profile.name) {
                store.message = "Account switching is still being implemented. Your sign-ins have not been changed."
            }
            menu.addItem(command)
        }
        return menu
    }
}
