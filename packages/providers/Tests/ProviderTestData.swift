import Foundation
import RationsCore
@testable import RationsProviders

enum ProviderTestData {
    static let now = Date(timeIntervalSince1970: 1_800_000_000)

    static func json(_ value: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: value)
    }

    static func profile(_ provider: ProviderID) -> AccountProfile {
        AccountIdentity.profile(provider, identity: "test-account", plan: "Test plan", email: "test@example.invalid")
    }
}
