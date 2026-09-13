import Foundation
@testable import RationsProviders
import Testing

struct ConnectionMergeTests {
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
