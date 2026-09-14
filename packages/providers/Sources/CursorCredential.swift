// Adapted from CodexBar's CursorAppAuth.swift; see Resources/CodexBarAttribution.txt.
import Foundation
import RationsCore

struct CursorCredential {
    let accessToken: String
    let userID: String
    let email: String?

    init(_ accessToken: String, now: Date = .now) throws {
        let parts = accessToken.split(separator: ".", omittingEmptySubsequences: false)
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
        let tokenCharacters = CharacterSet(charactersIn: alphabet)
        guard parts.count == 3, parts.allSatisfy({
            !$0.isEmpty && $0.unicodeScalars.allSatisfy(tokenCharacters.contains)
        }),
              let claims = ProviderJSON.claims(accessToken), let subject = claims.string("sub"),
              let userID = subject.split(separator: "|").last.map(String.init),
              !userID.isEmpty, userID.unicodeScalars.allSatisfy({
                  tokenCharacters.contains($0) || $0 == "."
              }), let expiry = claims.number("exp") else { throw ProviderFailure.invalidResponse }
        guard expiry > now.addingTimeInterval(60).timeIntervalSince1970 else {
            throw ProviderFailure.notSignedIn("The Cursor sign-in expired. Open Cursor and reconnect this account.")
        }
        self.accessToken = accessToken
        self.userID = userID
        email = claims.string("email")
    }

    init(data: Data, now: Date = .now) throws {
        guard let token = try ProviderJSON(data).string("accessToken") else { throw ProviderFailure.invalidResponse }
        try self.init(token, now: now)
    }

    var cookieHeader: String { "WorkosCursorSessionToken=\(userID)%3A%3A\(accessToken)" }

    func connection(sourcePath: String? = nil) throws -> AccountConnection {
        let profile = AccountIdentity.profile(.cursor, identity: userID.lowercased(), plan: nil, email: email)
        return AccountConnection(
            profile: profile, credential: try JSONEncoder().encode(["accessToken": accessToken]), sourcePath: sourcePath
        )
    }
}
