import Foundation
import RationsCore

public enum VendorExecutable {
    public static func locate(_ provider: ProviderID) throws -> URL {
        let name: String
        switch provider {
        case .codex: name = "codex"
        case .claude: name = "claude"
        case .antigravity: name = "agy"
        case .grok: name = "grok"
        case .cursor: throw ProviderFailure.unavailable("Open Cursor to sign in.")
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [home.appendingPathComponent(".local/bin/\(name)"),
                          URL(fileURLWithPath: "/opt/homebrew/bin/\(name)"),
                          URL(fileURLWithPath: "/usr/local/bin/\(name)")]
        guard let executable = candidates.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) else {
            throw ProviderFailure.notSignedIn("Install \(name), sign in once, then connect this account.")
        }
        return executable
    }
}
