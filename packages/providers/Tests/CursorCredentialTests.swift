import Foundation
@testable import RationsProviders
import Testing

struct CursorCredentialTests {
    @Test
    func localSessionBuildsTheCursorCookieAndKeepsItsStableIdentity() throws {
        let token = try CursorTestData.token()
        let credential = try CursorCredential(token)
        #expect(credential.cookieHeader == "WorkosCursorSessionToken=test-account%3A%3A" + token)
        let saved = try credential.connection()
        #expect(saved.profile.id == ProviderTestData.profile(.cursor).id)
        #expect(saved.profile.provider == .cursor)
        #expect(saved.profile.email == "cursor@example.invalid")
        #expect(try CursorCredential(data: saved.credential).userID == credential.userID)
    }

    @Test(arguments: ["broken", "header.payload", "header.payload.signature\r\nCookie: extra"])
    func rejectsMalformedCredentials(_ token: String) {
        #expect(throws: ProviderFailure.self) { try CursorCredential(token) }
    }

    @Test(arguments: ["auth0|bad;cookie", "auth0|bad%20id"])
    func rejectsSubjectsThatCouldChangeTheCookie(_ subject: String) throws {
        let token = try CursorTestData.token(subject: subject)
        #expect(throws: ProviderFailure.self) { try CursorCredential(token) }
    }

    @Test(arguments: [-1.0, 60.0])
    func expiredOrExpiringSessionsRequireReconnect(_ seconds: Double) throws {
        let now = Date.now
        let token = try CursorTestData.token(expiry: now.addingTimeInterval(seconds))
        #expect(throws: ProviderFailure.self) { try CursorCredential(token, now: now) }
    }
}
