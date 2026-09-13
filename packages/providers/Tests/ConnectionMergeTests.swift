import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct ConnectionMergeTests {
    @Test
    func reconnectReplacesCredentialsWithoutChangingTheSavedAccount() throws {
        var saved = connection()
        saved.profile.name = "Work"
        var renewed = connection()
        renewed.credential = Data("renewed-fixture-credential".utf8)
        try ConnectionMerge.validate(renewed.profile, reconnecting: saved.profile)
        let result = ConnectionMerge.prepare(
            renewed, existing: saved, requestedName: "Different name", alreadyConnected: true
        )
        #expect(result.profile.id == saved.profile.id)
        #expect(result.profile.name == "Work")
        #expect(result.credential == renewed.credential)
        #expect(result.credential != saved.credential)
    }

    @Test(arguments: ProviderID.allCases)
    func reconnectRejectsASeparateAccountForEveryProvider(_ provider: ProviderID) {
        let saved = ProviderTestData.profile(provider)
        let other = AccountIdentity.profile(provider, identity: "other-account", plan: nil, email: nil)
        #expect(throws: ProviderFailure.self) { try ConnectionMerge.validate(other, reconnecting: saved) }
    }

    @Test
    func addingAnAccountDoesNotRequireAnExistingIdentity() throws {
        try ConnectionMerge.validate(ProviderTestData.profile(.claude), reconnecting: nil)
    }

    @Test
    func repeatedSignInKeepsTheExistingAccountName() {
        var saved = connection()
        saved.profile.name = "Work1"
        let result = ConnectionMerge.prepare(
            connection(), existing: saved, requestedName: "Work2", alreadyConnected: true
        )
        #expect(result.profile.name == "Work1")
        #expect(result.profile.id == saved.profile.id)
    }

    @Test
    func loginNameWinsOverConcurrentAutomaticDiscoveryForANewAccount() {
        let result = ConnectionMerge.prepare(
            connection(), existing: connection(), requestedName: "  Work2  ", alreadyConnected: false
        )
        #expect(result.profile.name == "Work2")
    }

    private func connection() -> AccountConnection {
        AccountConnection(profile: ProviderTestData.profile(.codex), credential: Data("fixture".utf8))
    }
}
