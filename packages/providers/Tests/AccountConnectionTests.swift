import Foundation
import RationsCore
@testable import RationsProviders
import Testing

struct AccountConnectionTests {
    @Test
    func savedAccountRetainsCredentialAliasAndCachedFailure() throws {
        var account = AccountConnection(profile: ProviderTestData.profile(.codex), credential: Data("fixture".utf8))
        account.profile.name = "Work"
        account.lastReading = AccountReading(
            profile: account.profile, rows: [], fetchedAt: ProviderTestData.now,
            error: "Unable to refresh"
        )
        let restored = try JSONDecoder().decode(AccountConnection.self, from: JSONEncoder().encode(account))
        #expect(restored.profile.name == "Work")
        #expect(restored.credential == account.credential)
        #expect(restored.lastReading?.isFresh(at: ProviderTestData.now) == false)
    }
}
