import Darwin
import Foundation

enum VendorProcess {
    static func run(_ executable: URL, arguments: [String], timeout: TimeInterval = 15) async throws -> Data {
        try await Task.detached(priority: .utility) {
            let process = Process()
            let output = Pipe()
            process.executableURL = executable
            process.arguments = arguments
            process.standardOutput = output
            process.standardError = FileHandle.nullDevice
            process.standardInput = FileHandle.nullDevice
            process.currentDirectoryURL = try runtimeDirectory()
            try process.run()
            ProviderProcesses.shared.add(process)
            let deadline = DispatchWorkItem { stop(process) }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: deadline)
            defer { deadline.cancel(); stop(process); ProviderProcesses.shared.remove(process) }
            var result = Data()
            while let chunk = try output.fileHandleForReading.read(upToCount: 65_536), !chunk.isEmpty {
                result.append(chunk)
                guard result.count < 2_000_000 else { throw ProviderFailure.invalidResponse }
            }
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw ProviderFailure.unavailable("The vendor command failed. Open its sign-in tool and reconnect.")
            }
            return result
        }.value
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
