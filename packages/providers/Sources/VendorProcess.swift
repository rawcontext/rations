import Darwin
import Foundation

enum VendorProcess {
    static func run(
        _ executable: URL, arguments: [String], timeout: TimeInterval = 15, directory: URL? = nil
    ) async throws -> Data {
        try Task.checkCancellation()
        let process = Process()
        let output = Pipe()
        process.executableURL = executable
        process.arguments = arguments
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice
        process.standardInput = FileHandle.nullDevice
        process.currentDirectoryURL = try directory ?? runtimeDirectory()
        try process.run()
        ProviderProcesses.shared.add(process)
        defer {
            stop(process)
            ProviderProcesses.shared.remove(process)
            try? output.fileHandleForReading.close()
        }
        try output.fileHandleForWriting.close()
        let descriptor = output.fileHandleForReading.fileDescriptor
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
        let data = try await collect(process, descriptor: descriptor, timeout: timeout)
        guard process.terminationStatus == 0 else {
            throw ProviderFailure.unavailable("The vendor command failed. Open its sign-in tool and reconnect.")
        }
        return data
    }

    private static func collect(_ process: Process, descriptor: Int32, timeout: TimeInterval) async throws -> Data {
        let deadline = ContinuousClock.now + .seconds(timeout)
        var result = Data()
        var buffer = [UInt8](repeating: 0, count: 65_536)
        while true {
            try Task.checkCancellation()
            guard ContinuousClock.now < deadline else { throw ProviderFailure.timedOut }
            let count = Darwin.read(descriptor, &buffer, buffer.count)
            if count > 0 { result.append(contentsOf: buffer.prefix(count)) }
            guard result.count < 2_000_000 else { throw ProviderFailure.invalidResponse }
            if !process.isRunning, count <= 0 { return result }
            if count <= 0 { try await Task.sleep(for: .milliseconds(50)) }
        }
    }

    static func runtimeDirectory() throws -> URL {
        let directory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Rations/Runtime", isDirectory: true)
        try FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700]
        )
        return directory
    }

    static func stop(_ process: Process) {
        guard process.isRunning else { return }
        process.terminate()
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            if process.isRunning { kill(process.processIdentifier, SIGKILL) }
        }
    }
}
