import AppKit
import RationsCore
import RationsProviders

@MainActor
enum ProviderSignIn {
    static func open(_ provider: ProviderID) throws {
        guard provider == .antigravity else { return }
        let executable = try VendorExecutable.locate(provider)
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Rations/SignIn", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]
        )
        let command = directory.appendingPathComponent(provider.rawValue + ".command")
        let quoted = "'" + executable.path.replacingOccurrences(of: "'", with: "'\\''") + "'"
        let script = "#!/bin/bash\n" + quoted
            + "\nprintf '\\nRations connects automatically after a new sign-in.\\n'\n"
        try Data(script.utf8).write(to: command, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: command.path)
        NSWorkspace.shared.open(command)
    }
}
