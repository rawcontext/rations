import Foundation
import RationsCore

enum CursorProvider {
    static func fetch(_ account: AccountConnection, using http: UsageHTTPClient) async throws -> AccountReading {
        let credential = try CursorCredential(data: account.credential)
        guard try credential.connection().profile.id == account.profile.id else {
            throw ProviderFailure.unavailable("The Cursor account changed. Reconnect it.")
        }
        guard let url = URL(string: "https://cursor.com/api/usage-summary") else {
            throw ProviderFailure.invalidResponse
        }
        let data = try await http.request(url, headers: ["Cookie": credential.cookieHeader])
        return try CursorUsageParser.parse(data, profile: account.profile, now: .now)
    }
}
