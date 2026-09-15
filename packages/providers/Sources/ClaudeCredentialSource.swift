import Foundation

enum ClaudeCredentialSource {
    static func capture(
        _ candidates: [Data], now: Date = .now,
        authenticate: (Data) async throws -> AccountConnection = { try await connection($0) }
    ) async throws -> AccountConnection? {
        let eligible = candidates.filter {
            guard let oauth = try? ProviderJSON($0).object("claudeAiOauth") else { return false }
            return oauth.string("accessToken") != nil && (expiry($0) ?? .distantFuture) > now.addingTimeInterval(60)
        }.sorted { (expiry($0) ?? .distantPast) > (expiry($1) ?? .distantPast) }
        for credential in eligible {
            do { return try await authenticate(credential) } catch let error as ProviderFailure {
                // A rejected source must not hide a newer sign-in or the CLI's own renewal path.
                if case .notSignedIn = error { continue }
                throw error
            }
        }
        return nil
    }

    static func connection(_ data: Data, path: URL? = nil) async throws -> AccountConnection {
        guard let token = try ProviderJSON(data).object("claudeAiOauth")?.string("accessToken"),
              let url = URL(string: "https://api.anthropic.com/api/oauth/profile") else {
            throw ProviderFailure.invalidResponse
        }
        let response = try await UsageHTTPClient().request(url, token: token)
        var profile = try ClaudeUsageParser.oauthProfile(response)
        profile.plan = try ProviderJSON(data).object("claudeAiOauth")?.string("subscriptionType")?.capitalized
        return AccountConnection(profile: profile, credential: data, sourcePath: path?.path)
    }

    static func cliConnection() async throws -> AccountConnection {
        let status = try await VendorProcess.run(try VendorExecutable.locate(.claude), arguments: ["auth", "status"])
        let profile = try ClaudeUsageParser.profile(status)
        return AccountConnection(profile: profile, credential: status, usesClaudeCLI: true)
    }

    private static func expiry(_ data: Data) -> Date? {
        (try? ProviderJSON(data).object("claudeAiOauth")?.number("expiresAt"))
            .map { Date(timeIntervalSince1970: $0 / 1000) }
    }
}
