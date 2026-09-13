import Foundation
import RationsCore

enum CredentialDiscovery {
    static func capture(
        _ provider: ProviderID, file: URL? = nil, interactive: Bool = false
    ) async throws -> AccountConnection {
        let home = FileManager.default.homeDirectoryForCurrentUser
        switch provider {
        case .codex:
            let root = ProcessInfo.processInfo.environment["CODEX_HOME"].map { URL(fileURLWithPath: $0) }
                ?? home.appendingPathComponent(".codex")
            return try codex(file ?? root.appendingPathComponent("auth.json"))
        case .grok:
            return try grok(file ?? home.appendingPathComponent(".grok/auth.json"))
        case .claude:
            return try await claude(file: file, interactive: interactive)
        case .antigravity:
            return try await antigravity(file: file, interactive: interactive)
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

    private static func grok(_ path: URL) throws -> AccountConnection {
        let data = try read(path, hint: "Run grok login, then connect the account.")
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

    private static func antigravity(file: URL?, interactive: Bool) async throws -> AccountConnection {
        var data = try file.map { try read($0, hint: "Select an Antigravity sign-in file.") }
            ?? antigravityCredential(interactive: interactive)
        let expiry = try ProviderJSON(data).object("token")?.string("expiry").flatMap(ProviderJSON.date)
        if file == nil, let expiry, expiry <= Date.now.addingTimeInterval(60) {
            _ = try await VendorProcess.run(try VendorExecutable.locate(.antigravity), arguments: ["models"])
            data = try antigravityCredential(interactive: interactive)
        }
        let root = try ProviderJSON(data)
        guard let claims = ProviderJSON.claims(root.string("id_token")), let id = claims.string("sub"),
              root.object("token")?.string("access_token") != nil else { throw ProviderFailure.invalidResponse }
        let profile = AccountIdentity.profile(.antigravity, identity: id, plan: nil, email: claims.string("email"))
        return AccountConnection(profile: profile, credential: data, sourcePath: file?.path)
    }

    private static func claude(file: URL?, interactive: Bool) async throws -> AccountConnection {
        if let file { return try await claudeOAuth(read(file, hint: "Select a Claude sign-in file."), path: file) }
        var candidates: [Data] = []
        let directory = ProcessInfo.processInfo.environment["CLAUDE_CONFIG_DIR"].map { URL(fileURLWithPath: $0) }
            ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")
        let path = directory.appendingPathComponent(".credentials.json")
        if let data = try? Data(contentsOf: path) { candidates.append(data) }
        candidates += (try? NativeKeychain.read(service: "Claude Code-credentials", interactive: interactive)) ?? []
        if let credential = candidates.first(where: { (try? ProviderJSON($0))?.object("claudeAiOauth") != nil }) {
            return try await claudeOAuth(credential, path: nil)
        }
        let status = try await VendorProcess.run(try VendorExecutable.locate(.claude), arguments: ["auth", "status"])
        let profile = try ClaudeUsageParser.profile(status)
        return AccountConnection(profile: profile, credential: status, usesClaudeCLI: true)
    }

    private static func claudeOAuth(_ data: Data, path: URL?) async throws -> AccountConnection {
        guard let token = try ProviderJSON(data).object("claudeAiOauth")?.string("accessToken"),
              let url = URL(string: "https://api.anthropic.com/api/oauth/profile") else {
            throw ProviderFailure.invalidResponse
        }
        let response = try await UsageHTTPClient().request(url, token: token)
        var profile = try ClaudeUsageParser.oauthProfile(response)
        profile.plan = try ProviderJSON(data).object("claudeAiOauth")?.string("subscriptionType")?.capitalized
        return AccountConnection(
            profile: profile, credential: data, sourcePath: path?.path
        )
    }

    private static func antigravityCredential(interactive: Bool) throws -> Data {
        guard let stored = try NativeKeychain.read(
            service: "gemini", account: "antigravity", interactive: interactive
        ).first else {
            throw ProviderFailure.notSignedIn("Sign in with Antigravity or agy, then connect the account.")
        }
        return NativeKeychain.unwrapGoKeyring(stored)
    }

    private static func read(_ path: URL, hint: String) throws -> Data {
        guard FileManager.default.fileExists(atPath: path.path) else { throw ProviderFailure.notSignedIn(hint) }
        let size = try path.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        guard size < 2_000_000 else { throw ProviderFailure.invalidResponse }
        return try Data(contentsOf: path)
    }
}
