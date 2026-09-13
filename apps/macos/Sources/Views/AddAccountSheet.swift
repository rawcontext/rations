import RationsCore
import SwiftUI
import UniformTypeIdentifiers

struct AddAccountSheet: View {
    let store: RationsStore
    let provider: ProviderID
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var connecting = false
    @State private var importing = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add \(provider.displayName) Account").font(.headline)
            TextField("Name", text: $name).textFieldStyle(.roundedBorder)
            Text("Sign in using the vendor's tool, then connect the account here. Existing accounts stay saved.")
                .font(.callout).foregroundStyle(.secondary)
            HStack {
                Button("Open Sign-In…") { store.signIn(provider) }
                Button("Import Sign-In File…") { importing = true }
            }
            if let error {
                Text(error).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            actions
        }
        .padding(20).frame(width: 400)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case let .success(url): connect(file: url)
            case let .failure(error): self.error = error.localizedDescription
            }
        }
    }

    private var actions: some View {
        HStack {
            if connecting { ProgressView().controlSize(.small) }
            Spacer()
            Button("Cancel", role: .cancel) { dismiss() }.keyboardShortcut(.cancelAction)
            Button("Connect Current Account") { connect() }.buttonStyle(.borderedProminent)
                .disabled(connecting).keyboardShortcut(.defaultAction)
        }
    }

    private func connect(file: URL? = nil) {
        connecting = true
        error = nil
        Task {
            let scoped = file?.startAccessingSecurityScopedResource() ?? false
            defer { if scoped { file?.stopAccessingSecurityScopedResource() }; connecting = false }
            do {
                try await store.connect(provider, name: name, file: file)
                dismiss()
            } catch { self.error = error.localizedDescription }
        }
    }
}
