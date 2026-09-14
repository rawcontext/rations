import Foundation
@testable import RationsProviders
import Security
import Testing

struct AntigravityCredentialSourceTests {
    @Test(arguments: [false, true])
    func validExistingAccessNeverPromptsOrRunsTheVendor(_ interactive: Bool) async throws {
        let credential = try token(expiringIn: 3600)
        var requests: [Bool] = []
        let source = AntigravityCredentialSource(read: {
            requests.append($0)
            return credential
        }, renew: { Issue.record("A current credential should not need renewal") })
        #expect(try await source.capture(interactive: interactive, now: ProviderTestData.now) == credential)
        #expect(requests == [false])
    }

    @Test(arguments: [false, true])
    func expiredCredentialIsRenewedBeforeTheOnlyPotentialPrompt(_ interactive: Bool) async throws {
        let expired = try token(expiringIn: -10)
        let renewed = try token(expiringIn: 3600)
        var events: [String] = []
        let source = AntigravityCredentialSource(read: {
            events.append($0 ? "interactive" : "silent")
            return events.count == 1 ? expired : renewed
        }, renew: { events.append("renew") })
        #expect(try await source.capture(interactive: interactive, now: ProviderTestData.now) == renewed)
        #expect(events == ["silent", "renew", interactive ? "interactive" : "silent"])
    }

    @Test
    func reconnectRenewsBeforeRequestingAccessToTheResultingItem() async throws {
        let renewed = try token(expiringIn: 3600)
        var events: [String] = []
        let source = AntigravityCredentialSource(read: { interactive in
            events.append(interactive ? "interactive" : "silent")
            guard interactive else { throw ProviderFailure.keychain(errSecInteractionNotAllowed) }
            return renewed
        }, renew: { events.append("renew") })
        #expect(try await source.capture(interactive: true, now: ProviderTestData.now) == renewed)
        #expect(events == ["silent", "renew", "interactive"])
    }

    @Test
    func backgroundAccessRefusalDoesNotLaunchTheVendorOrPrompt() async {
        let source = AntigravityCredentialSource(read: {
            #expect(!$0)
            throw ProviderFailure.keychain(errSecInteractionNotAllowed)
        }, renew: { Issue.record("Access refusal must not launch a vendor process") })
        await #expect(throws: ProviderFailure.self) { try await source.capture(interactive: false) }
    }

    @Test(arguments: [false, true])
    func failedOrCancelledRenewalDoesNotAskForKeychainAccess(_ cancelled: Bool) async {
        var requests: [Bool] = []
        let failure: any Error = cancelled ? CancellationError() : ProviderFailure.timedOut
        let source = AntigravityCredentialSource(read: {
            requests.append($0)
            throw ProviderFailure.keychain(errSecInteractionNotAllowed)
        }, renew: { throw failure })
        do {
            _ = try await source.capture(interactive: true)
            Issue.record("Expected the renewal failure")
        } catch {
            #expect(error.localizedDescription == failure.localizedDescription)
            #expect((error is CancellationError) == cancelled)
        }
        #expect(requests == [false])
    }

    private func token(expiringIn seconds: TimeInterval) throws -> Data {
        try ProviderTestData.json([
            "token": ["expiry": ProviderTestData.now.addingTimeInterval(seconds).ISO8601Format()]
        ])
    }
}
