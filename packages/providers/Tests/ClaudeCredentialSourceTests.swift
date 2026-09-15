import Foundation
@testable import RationsProviders
import Testing

struct ClaudeCredentialSourceTests {
    @Test
    func newestCredentialWinsOverEarlierFileCandidate() async throws {
        let old = try credential(remaining: 120)
        let fresh = try credential(remaining: 3600)
        let account = try await ClaudeCredentialSource.capture([old, fresh], now: ProviderTestData.now) {
            #expect($0 == fresh)
            return AccountConnection(profile: ProviderTestData.profile(.claude), credential: $0)
        }
        #expect(account?.credential == fresh)
    }

    @Test(arguments: [-3600.0, 0.0, 60.0])
    func expiredCredentialsUseTheCLIRenewalPath(_ remaining: Double) async throws {
        let expired = try credential(remaining: remaining)
        let account = try await ClaudeCredentialSource.capture([expired], now: ProviderTestData.now) { _ in
            Issue.record("An expired token must not be sent to the profile endpoint")
            throw ProviderFailure.invalidResponse
        }
        #expect(account == nil)
    }

    @Test
    func rejectedCredentialDoesNotPreventTryingAnotherSource() async throws {
        let rejected = try credential(remaining: 3600)
        let accepted = try credential(remaining: 120)
        let account = try await ClaudeCredentialSource.capture([rejected, accepted], now: ProviderTestData.now) {
            if $0 == rejected { throw ProviderFailure.notSignedIn("Rejected") }
            return AccountConnection(profile: ProviderTestData.profile(.claude), credential: $0)
        }
        #expect(account?.credential == accepted)
    }

    @Test
    func cooldownDoesNotTriggerAnotherRequestOrCLIFallback() async throws {
        let token = try credential(remaining: 3600)
        var attempts = 0
        await #expect(throws: ProviderFailure.self) {
            try await ClaudeCredentialSource.capture([token, token], now: ProviderTestData.now) { _ in
                attempts += 1
                throw ProviderFailure.rateLimited(ProviderTestData.now.addingTimeInterval(300))
            }
        }
        #expect(attempts == 1)
    }

    private func credential(remaining: Double) throws -> Data {
        try ProviderTestData.json(["claudeAiOauth": [
            "accessToken": "synthetic-token",
            "expiresAt": ProviderTestData.now.addingTimeInterval(remaining).timeIntervalSince1970 * 1000
        ]])
    }
}
