import Foundation
@testable import RationsProviders
import Testing

struct GrokCredentialSourceTests {
    @Test(arguments: [61.0, 3600.0])
    func currentTokensDoNotLaunchTheVendor(_ remaining: Double) async throws {
        let current = try credential(remaining: remaining)
        let source = GrokCredentialSource(read: { current }, renew: { Issue.record("Unexpected renewal") })
        #expect(try await source.capture(now: ProviderTestData.now) == current)
    }

    @Test(arguments: [-3600.0, 0.0, 60.0])
    func expiresSoonRenewsAndReadsThePublishedToken(_ remaining: Double) async throws {
        var stored = try credential(remaining: remaining)
        let updated = try credential(remaining: 21600)
        var renewals = 0
        let source = GrokCredentialSource(read: { stored }, renew: { renewals += 1; stored = updated })
        #expect(try await source.capture(now: ProviderTestData.now) == updated)
        #expect(renewals == 1)
    }

    @Test
    func unchangedTokenIsNotReportedAsRenewed() async throws {
        let expired = try credential(remaining: -60)
        let source = GrokCredentialSource(read: { expired }, renew: {})
        await #expect(throws: ProviderFailure.self) { try await source.capture(now: ProviderTestData.now) }
    }

    @Test
    func failedRenewalPreservesTheOriginalFailure() async throws {
        let expired = try credential(remaining: -60)
        var reads = 0
        let source = GrokCredentialSource(read: { reads += 1; return expired }, renew: { throw CancellationError() })
        await #expect(throws: CancellationError.self) { try await source.capture(now: ProviderTestData.now) }
        #expect(reads == 1)
    }

    private func credential(remaining: Double) throws -> Data {
        try ProviderTestData.json(["https://auth.x.ai::fixture": [
            "key": "synthetic-token", "expires_at": ProviderTestData.now.addingTimeInterval(remaining).ISO8601Format()
        ]])
    }
}
