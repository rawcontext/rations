import Foundation
import RationsCore

struct ProviderFetcher: Sendable {
    let http = UsageHTTPClient()

    func fetch(_ account: AccountConnection) async throws -> AccountReading {
        switch account.profile.provider {
        case .codex: return try await codex(account)
        case .claude: return try await claude(account)
        case .antigravity: return try await antigravity(account)
        case .grok: return try await grok(account)
        case .cursor: return try await CursorProvider.fetch(account, using: http)
        }
    }

    private func codex(_ account: AccountConnection) async throws -> AccountReading {
        guard let tokens = try ProviderJSON(account.credential).object("tokens"),
              let token = tokens.string("access_token"), let id = tokens.string("account_id"),
              let url = URL(string: "https://chatgpt.com/backend-api/wham/usage") else {
            throw ProviderFailure.invalidResponse
        }
        let data = try await http.request(url, token: token, headers: ["ChatGPT-Account-Id": id])
        return try CodexUsageParser.parse(data, profile: account.profile, now: .now)
    }

    private func claude(_ account: AccountConnection) async throws -> AccountReading {
        if account.usesClaudeCLI {
            let before = try await ClaudeCredentialSource.cliConnection()
            guard before.profile.id == account.profile.id else { throw inactiveClaude() }
            let screen = try await ClaudeTerminalProbe.read()
            let after = try await ClaudeCredentialSource.cliConnection()
            guard after.profile.id == account.profile.id else { throw inactiveClaude() }
            return try ClaudeTerminalParser.parse(screen, profile: account.profile, now: .now)
        }
        guard let token = try ProviderJSON(account.credential).object("claudeAiOauth")?.string("accessToken"),
              let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            throw ProviderFailure.invalidResponse
        }
        let data = try await http.request(url, token: token, headers: ["anthropic-beta": "oauth-2025-04-20"])
        return try ClaudeUsageParser.parse(data, profile: account.profile, now: .now)
    }

    private func inactiveClaude() -> ProviderFailure {
        .notSignedIn("Sign in to this account in Claude Code and reconnect it. Its CLI login is no longer active.")
    }

    private func antigravity(_ account: AccountConnection) async throws -> AccountReading {
        guard let token = try ProviderJSON(account.credential).object("token")?.string("access_token"),
              let url = URL(string: "https://cloudcode-pa.googleapis.com/v1internal:loadCodeAssist") else {
            throw ProviderFailure.invalidResponse
        }
        let metadata = ["ideType": "ANTIGRAVITY", "platform": "PLATFORM_UNSPECIFIED", "pluginType": "GEMINI"]
        let body = try JSONEncoder().encode(["metadata": metadata])
        let data = try await http.request(url, token: token, body: body, headers: ["User-Agent": "antigravity"])
        let assist = try ProviderJSON(data)
        var request: [String: String] = [:]
        if let project = assist.string("cloudaicompanionProject") { request["project"] = project }
        let quota = try await http.request(
            "https://cloudcode-pa.googleapis.com/v1internal:retrieveUserQuotaSummary",
            token: token, object: request, headers: ["User-Agent": "antigravity"]
        )
        let plan = assist.object("paidTier")?.string("name") ?? assist.object("currentTier")?.string("name")
        return try AntigravityUsageParser.parse(quota, profile: updatingPlan(account.profile, plan), now: .now)
    }

    private func grok(_ account: AccountConnection) async throws -> AccountReading {
        let entry = try CredentialDiscovery.grokEntry(account.credential)
        guard let token = entry.string("key"),
              let url = URL(string: "https://cli-chat-proxy.grok.com/v1/billing?format=credits"),
              let settingsURL = URL(string: "https://cli-chat-proxy.grok.com/v1/settings") else {
            throw ProviderFailure.invalidResponse
        }
        let headers = ["x-xai-token-auth": "xai-grok-cli"]
        async let billing = http.request(url, token: token, headers: headers)
        let settings = try? await http.request(settingsURL, token: token, headers: headers)
        let plan = settings.flatMap { try? ProviderJSON($0).string("subscription_tier_display") }
        return try GrokUsageParser.parse(try await billing, profile: updatingPlan(account.profile, plan), now: .now)
    }

    private func updatingPlan(_ profile: AccountProfile, _ plan: String?) -> AccountProfile {
        AccountProfile(
            id: profile.id, provider: profile.provider,
            name: profile.name,
            plan: plan ?? profile.plan, email: profile.email
        )
    }
}
