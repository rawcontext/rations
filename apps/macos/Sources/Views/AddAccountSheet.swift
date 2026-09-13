import RationsCore
import SwiftUI

struct AddAccountSheet: View {
    let store: RationsStore
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Codex Account").font(.headline)
            TextField("Name", text: $name).textFieldStyle(.roundedBorder)
            Text("Shown in the menu and used when switching. You can rename it later.")
                .font(.caption).foregroundStyle(.secondary)
            Text("This design preview adds a sample account. It does not read or change your Codex sign-in.")
                .font(.callout)
            HStack {
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
                Button("Add Preview Account", action: add).buttonStyle(.borderedProminent)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20).frame(width: 372)
    }

    private func add() {
        guard store.isPreview else { return }
        let profile = AccountProfile(
            id: UUID().uuidString, provider: .codex, name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            plan: "Preview", email: nil
        )
        store.accounts.append(AccountReading(
            profile: profile, rows: [QuotaRow(id: "main", windows: [])], fetchedAt: .now
        ))
        dismiss()
    }
}
