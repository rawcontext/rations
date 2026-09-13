import RationsCore
import SwiftUI

struct ProviderSettingsRow: View {
    let provider: ProviderID
    let store: RationsStore
    let showsToggle: Bool

    private var accounts: [AccountReading] { store.accounts(for: provider) }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(provider.displayName)
                Text(accountDescription)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if showsToggle {
                Button("Accounts ›") { store.selectedTab = .accounts }.buttonStyle(.link)
            }
            Text(accounts.isEmpty ? "Not signed in" : "Connected")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(accounts.isEmpty ? .orange : .green)
            if showsToggle {
                Toggle("Enable " + provider.displayName, isOn: store.enabledBinding(for: provider))
                    .labelsHidden().toggleStyle(.switch).controlSize(.mini)
            }
        }
        .frame(minHeight: 32)
    }

    private var accountDescription: String {
        accounts.count > 1 ? "\(accounts.count) accounts" : accounts.first?.profile.plan ?? "No account connected"
    }
}
