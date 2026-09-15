import Foundation
import RationsCore

enum CredentialDiscovery {
    static func capture(
        _ provider: ProviderID, file: URL? = nil, interactive: Bool = false, forceRenewal: Bool = false
    ) async throws -> AccountConnection {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch provider {
        case .codex:
            let root = ProcessInfo.processInfo.environment["CODEX_HOME"].map { URL(fileURLWithPath: $0) }
                ?? home.appendingPathComponent(".codex")
            return try codex(file ?? root.appendingPathComponent("auth.json"))
        case .grok:
            let path = file ?? home.appendingPathComponent(".grok/auth.json")
            let load = { try read(path, hint: "Run grok login, then connect the account.") }
            let data = if file == nil {
                try await GrokCredentialSource(read: load).capture(forceRenewal: forceRenewal)
            } else { try load() }
            return try grok(data, path: path)
        case .claude:
            return try await claude(file: file, interactive: interactive, forceRenewal: forceRenewal)
        case .antigravity:
            return try await antigravity(file: file, interactive: interactive, forceRenewal: forceRenewal)
        case .cursor:
            let credential = try file.map {
                try CursorCredential(data: read($0, hint: "Select a Cursor sign-in file."))
            } ?? CursorCredential(CursorAppAuth.readToken())
            return try credential.connection(sourcePath: file?.path)
        }
    }

    private static func codex(_ path: URL) throws -> AccountConnection {
        let data = try read(path, hint: "Sign in with codex login, then connect the account.")
        let root = try ProviderJSON(data)
        guard let token = root.object("tokens"), token.string("access_token") != nil,
              let id = token.string("account_id") else {
            throw ProviderFailure.notSignedIn("A ChatGPT subscription sign-in is required. Run codex login.")
        }
        let claims = ProviderJSON.claims(token.string("id_token"))
        let plan = claims?.object("https://api.openai.com/auth")?.string("chatgpt_plan_type")?.capitalized
        let profile = AccountIdentity.profile(.codex, identity: id, plan: plan, email: claims?.string("email"))
        return AccountConnection(profile: profile, credential: data, sourcePath: path.path)
    }

    private static func grok(_ data: Data, path: URL) throws -> AccountConnection {
        let entry = try grokEntry(data)
        guard let id = entry.string("user_id") ?? entry.string("principal_id") else {
            throw ProviderFailure.invalidResponse
        }
        let profile = AccountIdentity.profile(.grok, identity: id, plan: nil, email: entry.string("email"))
        return AccountConnection(profile: profile, credential: data, sourcePath: path.path)
    }

    static func grokEntry(_ data: Data) throws -> ProviderJSON {
        let root = try ProviderJSON(data)
        let keys = root.values.keys.sorted {
            $0.hasPrefix("https://auth.x.ai::") && !$1.hasPrefix("https://auth.x.ai::")
        }
        for key in keys where key.hasPrefix("https://auth.x.ai::") || key == "https://accounts.x.ai/sign-in" {
            if let entry = root.object(key), entry.string("key") != nil { return entry }
        }
        throw ProviderFailure.notSignedIn("Run grok login, then connect the account.")
    }

    private static func antigravity(
        file: URL?, interactive: Bool, forceRenewal: Bool
    ) async throws -> AccountConnection {
        let data: Data
        if let file {
            data = try read(file, hint: "Select an Antigravity sign-in file.")
        } else {
            data = try await AntigravityCredentialSource().capture(interactive: interactive, forceRenewal: forceRenewal)
        }
        let root = try ProviderJSON(data)
        guard let claims = ProviderJSON.claims(root.string("id_token")), let id = claims.string("sub"),
              root.object("token")?.string("access_token") != nil else { throw ProviderFailure.invalidResponse }
        let profile = AccountIdentity.profile(.antigravity, identity: id, plan: nil, email: claims.string("email"))
        return AccountConnection(profile: profile, credential: data, sourcePath: file?.path)
    }

    private static func claude(file: URL?, interactive: Bool, forceRenewal: Bool) async throws -> AccountConnection {
        if let file {
            let data = try read(file, hint: "Select a Claude sign-in file.")
            return try await ClaudeCredentialSource.connection(data, path: file)
        }
        var candidates: [Data] = []
        let directory = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        let path = directory.appendingPathComponent(".credentials.json")
        if let data = try? Data(contentsOf: path) { candidates.append(data) }
        candidates += (try? NativeKeychain.read(service: "Claude Code-credentials", interactive: interactive)) ?? []
        if !forceRenewal, let account = try await ClaudeCredentialSource.capture(candidates) { return account }
        return try await ClaudeCredentialSource.cliConnection()
    }

    private static func read(_ path: URL, hint: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: path.path) else { throw ProviderFailure.notSignedIn(hint) }
        let size = try path.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size < 2_000_000 else { throw ProviderFailure.invalidResponse }
        return try Data(contentsOf: path)
    }
}
