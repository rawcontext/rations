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
                if let error = account.error {
                    Text(error).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer()
            if !active {
                Button("Remove") { store.remove(account.id) }.buttonStyle(.plain)
                    .foregroundStyle(.secondary).opacity(hovering ? 1 : 0)
                    .accessibilityLabel("Remove " + account.profile.name)
            }
            if account.issue?.requiresReconnect == true {
                Button("Reconnect") { store.reconnect(account.id) }.controlSize(.small)
            } else if account.issue == .unavailable {
                Button("Refresh") { store.refresh(manual: true) }.controlSize(.small).disabled(store.isRefreshing)
            }
            Text(statusLabel)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(statusColor)
        }
        .frame(minHeight: 32).onHover { hovering = $0 }
    }

    private var statusLabel: String {
        if let issue = account.issue { return issue.label }
        return active ? "Signed in" : "Connected"
    }

    private var statusColor: Color {
        if account.issue == .verifying { return .secondary }
        if account.issue != nil { return .orange }
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
