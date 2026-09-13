import Foundation
import RationsCore

struct LoginCommand: Sendable {
    let executable: URL
    let arguments: [String]
    let directory: URL
    let environment: [String: String]

    static func make(
        _ provider: ProviderID, directory: URL, executable: URL? = nil,
        environment: [String: String] = ProcessInfo.processInfo.environment
    ) throws -> Self {
        var environment = environment
        let arguments: [String]
        switch provider {
        case .codex:
            environment["CODEX_HOME"] = directory.path
            arguments = ["login", "-c", "cli_auth_credentials_store=\"file\""]
        case .claude: arguments = ["auth", "login", "--claudeai"]
        case .grok: arguments = ["login", "--oauth"]
        case .antigravity: throw ProviderFailure.unavailable("Use Antigravity's sign-in window.")
        }
        return Self(
            executable: try executable ?? VendorExecutable.locate(provider), arguments: arguments,
            directory: directory, environment: environment
        )
    }
}
