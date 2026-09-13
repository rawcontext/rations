import RationsCore
import SwiftUI

struct AccountsSettingsView: View {
    @Bindable var store: RationsStore

    var body: some View {
        Form {
            if let notice = store.connectionNotice { Text(notice).foregroundStyle(.secondary) }
            ForEach(ProviderID.allCases) { provider in accountSection(provider) }
        }
        .formStyle(.grouped)
        .sheet(item: $store.addingProvider) { provider in AddAccountSheet(store: store, provider: provider) }
    }

    private func accountSection(_ provider: ProviderID) -> some View {
        Section {
            ForEach(store.accounts(for: provider)) { account in
                AccountSettingsRow(account: account, store: store)
            }
            if store.accounts(for: provider).isEmpty {
                Text("No saved accounts").foregroundStyle(.secondary)
            }
            Button("Add Another Account", systemImage: "plus") { store.signIn(provider, startImmediately: false) }
                .buttonStyle(.plain).foregroundStyle(Color.accentColor)
                .accessibilityLabel("Add " + provider.displayName + " account")
        } header: {
            Text(provider.displayName)
        } footer: {
            if let error = store.providerErrors[provider] { Text(error) }
        }
    }
}
