import RationsCore
import SwiftUI

struct AccountSettingsRow: View {
    let account: AccountReading
    let store: RationsStore
    @State private var hovering = false
    @State private var editing = false
    @State private var draft = ""
    private var active: Bool { store.isActive(account) }

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                nameEditor
                Text(accountDescription)
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !active {
                Button("Remove") { store.remove(account.id) }.buttonStyle(.plain)
                    .foregroundStyle(.secondary).opacity(hovering ? 1 : 0)
                    .accessibilityLabel("Remove " + account.profile.name)
            }
            if account.error != nil {
                Button("Reconnect") { store.reconnect(account.id) }.controlSize(.small)
            }
            Text(statusLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
        }
        .frame(minHeight: 32).onHover { hovering = $0 }
    }

    private var statusLabel: String {
        if account.error != nil { return "Needs attention" }
        return active ? "Signed in" : "Connected"
    }

    private var statusColor: Color {
        if account.error != nil { return .orange }
        return active ? .accentColor : .green
    }

    private var accountDescription: String {
        [account.profile.plan, account.profile.displayEmail(redacted: store.preferences.hidePersonalInformation)]
            .compactMap { $0 }.joined(separator: " · ")
    }

    private var nameEditor: some View {
        HStack(spacing: 6) {
            if editing {
                TextField("Account name", text: $draft).textFieldStyle(.roundedBorder)
                    .onSubmit { store.rename(account.id, to: draft); editing = false }
                    .onExitCommand { editing = false }
            } else {
                Text(account.profile.name)
                Button {
                    draft = account.profile.name
                    editing = true
                } label: {
                    Image(systemName: "pencil").font(.system(size: 10)).foregroundStyle(.secondary)
                }
                .buttonStyle(.plain).accessibilityLabel("Rename " + account.profile.name)
            }
        }
    }
}
