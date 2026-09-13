import Foundation
import RationsCore

enum ManagedSignIn {
    static func run(
        _ provider: ProviderID, progress: @escaping @Sendable (SignInProgress) -> Void
    ) async throws -> AccountConnection {
        let directory = try VendorProcess.runtimeDirectory().appendingPathComponent("login-" + UUID().uuidString)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700]
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        progress(.starting)
        try await LoginProcess.run(try LoginCommand.make(provider, directory: directory), progress: progress)
        try Task.checkCancellation()
        progress(.connecting)
        let file = provider == .codex ? directory.appendingPathComponent("auth.json") : nil
        var account = try await CredentialDiscovery.capture(provider, file: file, interactive: true)
        account.sourcePath = nil
        return account
    }
}
