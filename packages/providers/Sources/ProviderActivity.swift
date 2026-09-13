import Foundation
import RationsCore

struct ProviderActivity {
    private(set) var versions: [ProviderID: UUID] = [:]
    private var operations: [ProviderID: UUID] = [:]

    var busy: Set<ProviderID> { Set(operations.keys) }

    mutating func begin(_ provider: ProviderID) -> UUID {
        let token = UUID()
        versions[provider] = token
        operations[provider] = token
        return token
    }

    mutating func finish(_ provider: ProviderID, token: UUID) {
        guard operations[provider] == token else { return }
        operations[provider] = nil
        versions[provider] = UUID()
    }

    func accepts(_ provider: ProviderID, version: UUID?) -> Bool {
        operations[provider] == nil && versions[provider] == version
    }
}
