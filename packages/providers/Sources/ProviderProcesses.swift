import Darwin
import Foundation

public final class ProviderProcesses: @unchecked Sendable {
    public static let shared = ProviderProcesses()
    private let lock = NSLock()
    private var processes: [Int32: Process] = [:]

    private init() {}

    func add(_ process: Process) {
        lock.lock()
        defer { lock.unlock() }
        processes[process.processIdentifier] = process
    }

    func remove(_ process: Process) {
        lock.lock()
        defer { lock.unlock() }
        processes[process.processIdentifier] = nil
    }

    public func stopAll() {
        lock.lock()
        let running = Array(processes.values)
        processes.removeAll()
        lock.unlock()
        for process in running where process.isRunning { kill(process.processIdentifier, SIGKILL) }
    }
}
