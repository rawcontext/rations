import Foundation
import RationsCore
@testable import RationsProviders
import Security
import Testing

struct ConnectionProblemTests {
    @Test
    func temporaryFailuresDoNotAskTheUserToSignInAgain() {
        let failures: [ProviderFailure] = [.rateLimited(.now), .timedOut, .invalidResponse, .unavailable("Offline")]
        for failure in failures {
            #expect(!ConnectionProblem(failure).kind.requiresReconnect)
        }
        #expect(ConnectionProblem(ProviderFailure.rateLimited(.now)).kind == .cooldown)
    }

    @Test
    func authenticationAndKeychainFailuresHaveDifferentActions() {
        #expect(ConnectionProblem(ProviderFailure.notSignedIn("Rejected")).kind == .authentication)
        let denied = ConnectionProblem(ProviderFailure.keychain(errSecInteractionNotAllowed))
        #expect(denied.kind == .approval)
        #expect(denied.kind.requiresReconnect)
    }

    @Test
    func oldSavedReadingsDecodeWithoutANewIssueField() throws {
        let reading = AccountReading(
            profile: ProviderTestData.profile(.grok), rows: [], fetchedAt: nil, error: "Old error"
        )
        let data = try JSONEncoder().encode(reading)
        let restored = try JSONDecoder().decode(AccountReading.self, from: data)
        #expect(restored.issue == .unavailable)
        #expect(restored.error == "Old error")
    }
}
