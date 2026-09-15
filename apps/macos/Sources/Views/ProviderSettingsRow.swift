import RationsCore
import SwiftUI

struct ProviderSettingsRow: View {
    let provider: ProviderID
    let store: RationsStore

    private var accounts: [AccountReading] { store.accounts(for: provider) }
    private var disabled: Bool { store.preferences.disabledProviders.contains(provider) }
    private var issue: ConnectionIssue? {
        let issues = accounts.compactMap(\.issue)
        return issues.first(where: \.requiresReconnect) ?? store.providerErrors[provider]?.kind ?? issues.first
    }

    private var explanation: String {
        var messages = accounts.compactMap(\.error)
        if let error = store.providerErrors[provider] { messages.append("Native sign-in: " + error.message) }
        return Array(Set(messages)).sorted().joined(separator: "\n")
    }

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
        .help(explanation.isEmpty ? statusLabel : explanation)
    }

    private var statusLabel: String {
        if disabled { return "Disabled" }
        if let issue { return issue.label }
        return accounts.isEmpty ? "Not connected" : "Connected"
    }

    private var statusColor: Color {
        if disabled { return .secondary }
        if issue == .verifying { return .secondary }
        return issue != nil || accounts.isEmpty ? .orange : .green
    }

    private var accountDescription: String {
        accounts.count > 1 ? "\(accounts.count) accounts" : accounts.first?.profile.plan ?? "No account connected"
    }
}
