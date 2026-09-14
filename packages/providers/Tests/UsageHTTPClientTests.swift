import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct UsageHTTPClientTests {
    @Test
    func quotaRequestUsesBearerAndVendorHeadersWithoutCookies() async throws {
        let data = try await client().request(
            "https://example.invalid/200", token: "synthetic-test-token", object: ["project": "fixture"],
            headers: ["User-Agent": "antigravity"]
        )
        let response = try ProviderJSON(data)
        #expect(response.string("method") == "POST")
        #expect(response.string("authorization") == "Bearer synthetic-test-token")
        #expect(response.string("userAgent") == "antigravity")
        #expect(response.string("cookie") == nil)
    }

    @Test(arguments: [401, 403, 429, 500])
    func unsuccessfulResponsesDoNotBecomeUsage(_ status: Int) async throws {
        let url = try #require(URL(string: "https://example.invalid/\(status)"))
        await #expect(throws: ProviderFailure.self) { try await client().request(url, token: "fixture") }
    }

    @Test
    func cursorRequestUsesOnlyItsExplicitSessionCookie() async throws {
        let url = try #require(URL(string: "https://example.invalid/200"))
        let cookie = "WorkosCursorSessionToken=fixture%3A%3Atoken"
        let response = try ProviderJSON(await client().request(url, headers: ["Cookie": cookie]))
        #expect(response.string("method") == "GET")
        #expect(response.string("authorization") == nil)
        #expect(response.string("cookie") == cookie)
    }

    @Test
    func retryAfterSupportsSecondsAndHTTPDates() throws {
        let now = try #require(ProviderJSON.date("2026-09-13T09:00:00Z"))
        #expect(UsageHTTPClient.retryDate("600", now: now) == now.addingTimeInterval(600))
        #expect(UsageHTTPClient.retryDate("-10", now: now) == now.addingTimeInterval(60))
        #expect(UsageHTTPClient.retryDate("Sun, 13 Sep 2026 09:10:00 GMT", now: now) == now.addingTimeInterval(600))
        #expect(UsageHTTPClient.retryDate("unrecognized", now: now) == now.addingTimeInterval(300))
    }

    private func client() -> UsageHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [UsageStubProtocol.self]
        configuration.httpCookieStorage = nil
        return UsageHTTPClient(session: URLSession(configuration: configuration))
    }
}
