import AppKit
import RationsCore
import RationsProviders
import SwiftUI
import UniformTypeIdentifiers

struct AddAccountSheet: View {
    let store: RationsStore
    let provider: ProviderID
    let reconnectingAccount: AccountProfile?
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var importing = false
    @State private var operation = SignInOperation()
    @State private var importError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            accountHeading
            status
            if let error = operation.error ?? importError {
                Text(error).font(.caption).foregroundStyle(.red).fixedSize(horizontal: false, vertical: true)
            }
            if !operation.isRunning, reconnectingAccount == nil { otherOptions }
            actions
        }
        .padding(20).frame(width: 400)
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            switch result {
            case let .success(url): connect(file: url)
            case let .failure(error): importError = error.localizedDescription
            }
        }
        .onAppear {
            if reconnectingAccount != nil || store.automaticallyStartSignIn { signIn() }
        }
        .onDisappear { operation.cancel() }
        .onChange(of: operation.completed) { _, completed in
            if completed { NSApp.activate(ignoringOtherApps: true); dismiss() }
        }
        .onChange(of: operation.error) { _, error in
            if error != nil { NSApp.activate(ignoringOtherApps: true) }
        }
    }

    private var accountHeading: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let account = reconnectingAccount {
                Text("Reconnect \(account.name)").font(.headline)
                if let email = account.displayEmail(redacted: store.preferences.hidePersonalInformation) {
                    Text(email).font(.callout).foregroundStyle(.secondary)
                }
                Text("Sign in to the same \(provider.displayName) account to restore access.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                Text("Add \(provider.displayName) Account").font(.headline)
                TextField("Account name (optional)", text: $name).textFieldStyle(.roundedBorder)
                    .disabled(operation.isRunning)
            }
        }
    }

    private var status: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if operation.isRunning { ProgressView().controlSize(.small) }
                Text(statusText).font(.callout).foregroundStyle(.secondary)
            }
            if operation.isRunning, case let .waitingForBrowser(url) = operation.progress, let url {
                Button("Open browser again") { NSWorkspace.shared.open(url) }.buttonStyle(.link)
            }
        }
    }

    private var statusText: String {
        guard operation.isRunning else { return "Finish signing in and this account will connect automatically." }
        switch operation.progress {
        case .starting: return "Starting sign-in…"
        case .waitingForBrowser:
            return provider == .antigravity
                ? "Finish signing in through Antigravity…" : "Complete sign-in in your browser…"
        case .connecting: return "Connecting your account…"
        }
    }

    private var otherOptions: some View {
        DisclosureGroup("Other options") {
            HStack {
                Button("Use existing sign-in") { connect() }
                Button("Import sign-in file…") { importing = true }
            }
            .padding(.top, 8)
        }
        .font(.callout)
    }

    private var actions: some View {
        HStack {
            Spacer()
            Button("Cancel", role: .cancel) { operation.cancel(); dismiss() }.keyboardShortcut(.cancelAction)
            if !operation.isRunning {
                Button("Sign in with \(provider.displayName)") { signIn() }
                    .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
            }
        }
    }

    private func signIn() {
        let accountName = reconnectingAccount?.name ?? name
        importError = nil
        operation.start { progress in
            try await store.completeSignIn(
                provider, name: accountName, progress: progress, reconnecting: reconnectingAccount?.id
            )
        }
    }

    private func connect(file: URL? = nil) {
        let accountName = name
        importError = nil
        operation.start { progress in
            progress(.connecting)
            let scoped = file?.startAccessingSecurityScopedResource() ?? false
            defer { if scoped { file?.stopAccessingSecurityScopedResource() } }
            try await store.connect(provider, name: accountName, file: file)
        }
    }
}
