import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct AccountFetchResultTests {
    @Test
    func rejectedAccessTokenRecoversWithoutDiscardingTheAccount() async {
        let saved = account()
        let result = await AccountFetchResult.fetch(saved, request: {
            if $0.credential == saved.credential { throw ProviderFailure.notSignedIn("Rejected") }
            return AccountReading(profile: $0.profile, rows: [], fetchedAt: ProviderTestData.now)
        }, recover: {
            var updated = $0
            updated.credential = Data("renewed".utf8)
            return updated
        })
        #expect(result.failure == nil)
        #expect(result.reading?.profile.id == saved.profile.id)
        #expect(result.connection.credential == Data("renewed".utf8))
    }

    @Test
    func cooldownDoesNotStartCredentialRecovery() async {
        let result = await AccountFetchResult.fetch(account(), request: { _ in
            throw ProviderFailure.rateLimited(ProviderTestData.now)
        }, recover: { _ in
            Issue.record("Rate limiting must not refresh credentials")
            throw ProviderFailure.invalidResponse
        })
        #expect(result.failure?.kind == .cooldown)
    }

    @Test
    func anotherNativeAccountCannotReplaceTheSavedAccount() async {
        let saved = account()
        let result = await AccountFetchResult.fetch(saved, request: { _ in
            throw ProviderFailure.notSignedIn("Rejected")
        }, recover: {
            var wrong = $0
            wrong.profile = AccountIdentity.profile(.grok, identity: "different-account", plan: nil, email: nil)
            return wrong
        })
        #expect(result.reading == nil)
        #expect(result.connection.profile.id == saved.profile.id)
        #expect(result.connection.credential == saved.credential)
        #expect(result.failure?.kind == .authentication)
    }

    @Test
    func aSecondRejectionStopsAndRetainsTheRenewedCredential() async {
        let result = await AccountFetchResult.fetch(account(), request: { _ in
            throw ProviderFailure.notSignedIn("Still rejected")
        }, recover: {
            #expect($0.credential == Data("original".utf8))
            var updated = $0
            updated.credential = Data("renewed".utf8)
            return updated
        })
        #expect(result.failure?.kind == .authentication)
        #expect(result.connection.credential == Data("renewed".utf8))
    }

    private func account() -> AccountConnection {
        AccountConnection(profile: ProviderTestData.profile(.grok), credential: Data("original".utf8))
    }
}
