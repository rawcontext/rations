import Foundation
import RationsCore

struct AccountConnection: Codable, Sendable {
    var profile: AccountProfile
    var credential: Data
    var sourcePath: String?
    var usesClaudeCLI = false
    var lastReading: AccountReading?

    init(profile: AccountProfile, credential: Data, sourcePath: String? = nil, usesClaudeCLI: Bool = false) {
        self.profile = profile
        self.credential = credential
        self.sourcePath = sourcePath
        self.usesClaudeCLI = usesClaudeCLI
    }
}
