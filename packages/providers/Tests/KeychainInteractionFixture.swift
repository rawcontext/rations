import Foundation

final class KeychainInteractionFixture: @unchecked Sendable {
    private let lock = NSLock()
    private var allowed = true
    private var changes: [Bool] = []

    func getAllowed() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return allowed
    }

    func setAllowed(_ value: Bool) {
        lock.lock()
        defer { lock.unlock() }
        allowed = value
        changes.append(value)
    }

    var history: [Bool] {
        lock.lock()
        defer { lock.unlock() }
        return changes
    }
}
