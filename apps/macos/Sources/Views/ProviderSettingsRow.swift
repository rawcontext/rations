import RationsCore
import SwiftUI

struct ProviderSettingsRow: View {
    let provider: ProviderID
    let store: RationsStore
    let showsToggle: Bool

    private var accounts: [AccountReading] { store.accounts.filter { $0.profile.provider == provider } }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(provider.displayName)
                Text(accounts.first?.profile.plan ?? "No account connected")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if provider == .codex, showsToggle {
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
}
