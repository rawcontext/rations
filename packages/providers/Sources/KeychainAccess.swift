import Foundation
import Security

final class KeychainAccess: @unchecked Sendable {
    static let shared = KeychainAccess()
    private let lock = NSLock()
    private let getAllowed: @Sendable () throws -> Bool
    private let setAllowed: @Sendable (Bool) throws -> Void

    init(
        getAllowed: @escaping @Sendable () throws -> Bool = KeychainAccess.interactionAllowed,
        setAllowed: @escaping @Sendable (Bool) throws -> Void = KeychainAccess.setInteractionAllowed
    ) {
        self.getAllowed = getAllowed
        self.setAllowed = setAllowed
    }

    func perform<Value>(interactive: Bool = false, _ operation: () throws -> Value) throws -> Value {
        lock.lock()
        defer { lock.unlock() }
        let previous = try getAllowed()
        try setAllowed(interactive)
        defer { try? setAllowed(previous) }
        return try operation()
    }

    private static func interactionAllowed() throws -> Bool {
        var allowed = DarwinBoolean(false)
        let status = SecKeychainGetUserInteractionAllowed(&allowed)
        guard status == errSecSuccess else { throw ProviderFailure.keychain(status) }
        return allowed.boolValue
    }

    private static func setInteractionAllowed(_ allowed: Bool) throws {
        // LAContext alone does not suppress legacy login-keychain ACL dialogs.
        let status = SecKeychainSetUserInteractionAllowed(allowed)
        guard status == errSecSuccess else { throw ProviderFailure.keychain(status) }
    }
}
