import Foundation
import RationsCore

enum ConnectionMerge {
    static func prepare(
        _ incoming: AccountConnection, existing: AccountConnection?, requestedName: String, alreadyConnected: Bool
    ) -> AccountConnection {
        var account = incoming
        let name = requestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if alreadyConnected, let existing {
            account.profile.name = existing.profile.name
        } else if !name.isEmpty {
            account.profile.name = name
        }
        account.profile.plan = account.profile.plan ?? existing?.profile.plan
        account.lastReading = existing?.lastReading
        return account
    }
}
