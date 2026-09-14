import Foundation
import RationsCore
@testable import RationsProviders
import Security
import Testing

struct ExternalSignInWatcherTests {
    @Test(arguments: [
        ProviderFailure.keychain(errSecAuthFailed), .keychain(errSecUserCanceled),
        .keychain(errSecInteractionNotAllowed), .timedOut
    ])
    func failedReconnectDoesNotOpenAnotherSignInOrRetryThePrompt(_ failure: ProviderFailure) async {
        let fixture = ExternalSignInFixture([.failure(failure)])
        await #expect(throws: ProviderFailure.self) {
            try await ExternalSignInWatcher.run(
                .antigravity, open: { await fixture.openBrowser() }, progress: { _ in },
                reconnecting: account().profile,
                captureCredentials: { _, interactive in try await fixture.capture(interactive: interactive) }
            )
        }
        #expect(await fixture.interactionRequests == [true])
        #expect(await !fixture.browserOpened)
    }

    @Test(arguments: [ProviderID.antigravity, .cursor])
    func reconnectCanReuseTheMatchingNativeSignIn(_ provider: ProviderID) async throws {
        let account = AccountConnection(profile: ProviderTestData.profile(provider), credential: Data("fixture".utf8))
        let fixture = ExternalSignInFixture([.success(account)])
        let captured = try await ExternalSignInWatcher.run(
            provider, open: { await fixture.openBrowser() }, progress: { _ in }, reconnecting: account.profile,
            captureCredentials: { _, interactive in try await fixture.capture(interactive: interactive) }
        )
        #expect(captured.profile.id == account.profile.id)
        #expect(await fixture.interactionRequests == [true])
        #expect(await !fixture.browserOpened)
    }

    @Test
    func cursorConnectionWaitsForTheNewNativeSignIn() async throws {
        let account = AccountConnection(profile: ProviderTestData.profile(.cursor), credential: Data("new".utf8))
        let fixture = ExternalSignInFixture([.failure(.notSignedIn("Sign in inside Cursor")), .success(account)])
        let captured = try await ExternalSignInWatcher.run(
            .cursor, open: { await fixture.openBrowser() }, progress: { _ in },
            captureCredentials: { _, interactive in try await fixture.capture(interactive: interactive) }
        )
        #expect(captured.profile.id == account.profile.id)
        #expect(await fixture.browserOpened)
        #expect(await fixture.interactionRequests == [false, false])
    }

    @Test
    func explicitLoginCanRequestAccessWhenTheVendorReplacesItsKeychainItem() async throws {
        let account = account()
        let fixture = ExternalSignInFixture([
            .failure(.notSignedIn("No existing account")), .failure(.keychain(errSecInteractionNotAllowed)),
            .success(account)
        ])
        let captured = try await ExternalSignInWatcher.run(
            .antigravity, open: { await fixture.openBrowser() }, progress: { _ in },
            captureCredentials: { _, interactive in try await fixture.capture(interactive: interactive) }
        )
        #expect(captured.credential == account.credential)
        #expect(await fixture.interactionRequests == [false, false, true])
        #expect(await fixture.browserOpened)
    }

    private func account() -> AccountConnection {
        AccountConnection(profile: ProviderTestData.profile(.antigravity), credential: Data("fixture".utf8))
    }
}
