import RationsCore
import SwiftUI

struct AccountsSettingsView: View {
    let store: RationsStore
    @State private var addingAccount = false

    var body: some View {
        Form {
            Section {
                ForEach(store.accounts.filter { $0.profile.provider == .codex }) { account in
                    AccountSettingsRow(account: account, store: store)
                }
                if store.accounts.isEmpty { Text("No saved accounts").foregroundStyle(.secondary) }
                Button("Add Another Account", systemImage: "plus") { addingAccount = true }
                    .buttonStyle(.plain).foregroundStyle(Color.accentColor).disabled(!store.isPreview)
            } header: {
                Text("Codex")
            } footer: {
                Text(store.isPreview
                    ? "Design preview. Rename or remove sample accounts; the signed-in account cannot be removed."
                    : "Named account sign-in and switching are still being implemented.")
            }
            otherAccounts
        }
        .formStyle(.grouped)
        .sheet(isPresented: $addingAccount) { AddAccountSheet(store: store) }
    }

    private var otherAccounts: some View {
        Section {
            ForEach(ProviderID.allCases.filter { $0 != .codex }) { provider in
                ProviderSettingsRow(provider: provider, store: store, showsToggle: false)
            }
        } header: {
            Text("Claude, Antigravity, Grok")
        } footer: {
            Text("One account each; switching isn't available for these yet.")
        }
    }
}
