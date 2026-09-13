import RationsCore
import SwiftUI

struct ProviderSettingsRow: View {
    let provider: ProviderID
    let store: RationsStore

    private var accounts: [AccountReading] { store.accounts(for: provider) }
    private var disabled: Bool { store.preferences.disabledProviders.contains(provider) }
    private var needsAttention: Bool { accounts.contains { $0.error != nil } || store.providerErrors[provider] != nil }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(provider.displayName)
                Text(accountDescription)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Accounts ›") { store.selectedTab = .accounts }.buttonStyle(.link)
            if accounts.isEmpty { Button("Sign In…") { store.signIn(provider) }.controlSize(.small) }
            Text(statusLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
            Toggle("Enable " + provider.displayName, isOn: store.enabledBinding(for: provider))
                .labelsHidden().toggleStyle(.switch).controlSize(.mini)
        }
        .frame(minHeight: 32)
    }

    private var statusLabel: String {
        if disabled { return "Disabled" }
        if needsAttention { return "Needs attention" }
        return accounts.isEmpty ? "Not connected" : "Connected"
    }

    private var statusColor: Color {
        if disabled { return .secondary }
        return needsAttention || accounts.isEmpty ? .orange : .green
    }

    private var accountDescription: String {
        accounts.count > 1 ? "\(accounts.count) accounts" : accounts.first?.profile.plan ?? "No account connected"
    }
}
