import CryptoKit
import Foundation
import RationsCore

enum AccountIdentity {
    static func profile(_ provider: ProviderID, identity: String, plan: String?, email: String?) -> AccountProfile {
        let digest = SHA256.hash(data: Data(identity.utf8)).map { String(format: "%02x", $0) }.joined()
        return AccountProfile(
            id: provider.rawValue + ":" + digest,
            provider: provider, name: plan ?? provider.displayName, plan: plan, email: email
        )
    }
}
