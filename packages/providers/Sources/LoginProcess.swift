import Darwin
import Foundation

enum LoginProcess {
    static func run(
        _ command: LoginCommand, progress: @escaping @Sendable (SignInProgress) -> Void,
        timeout: Duration = .seconds(300)
    ) async throws {
        try Task.checkCancellation()
        let child = Process()
        let output = Pipe()
        let input = Pipe()
        child.executableURL = command.executable
        child.arguments = command.arguments
        child.environment = command.environment
        child.currentDirectoryURL = command.directory
        child.standardOutput = output
        child.standardError = output
        child.standardInput = input
        try child.run()
        ProviderProcesses.shared.add(child)
        defer {
            VendorProcess.stop(child)
            ProviderProcesses.shared.remove(child)
            try? output.fileHandleForReading.close()
            try? input.fileHandleForWriting.close()
        }
        try output.fileHandleForWriting.close()
        let descriptor = output.fileHandleForReading.fileDescriptor
        _ = fcntl(descriptor, F_SETFL, O_NONBLOCK)
        progress(.waitingForBrowser(nil))
        let result = try await monitor(
            child, descriptor: descriptor, input: input, progress: progress, timeout: timeout
        )
        guard child.terminationStatus == 0 else {
            let hint = result.portInUse ? "Another sign-in is already open. Finish or cancel it, then try again."
                : "Sign-in did not finish. Try again and complete the approval in your browser."
            throw ProviderFailure.unavailable(hint)
        }
    }

    private static func monitor(
        _ child: Process, descriptor: Int32, input: Pipe,
        progress: @escaping @Sendable (SignInProgress) -> Void, timeout: Duration
    ) async throws -> LoginOutput {
        let deadline = ContinuousClock.now + timeout
        var output = LoginOutput()
        var sentReturn = false
        var publishedURL: URL?
        var buffer = [UInt8](repeating: 0, count: 16_384)
        while true {
            try Task.checkCancellation()
            guard ContinuousClock.now < deadline else {
                throw ProviderFailure.unavailable(
                    "Sign-in timed out. Try again when you're ready to finish in the browser."
                )
            }
            let count = Darwin.read(descriptor, &buffer, buffer.count)
            if count > 0 { try output.append(buffer.prefix(count)) }
            if let url = output.authorizationURL, url != publishedURL {
                progress(.waitingForBrowser(url))
                publishedURL = url
            }
            if output.needsReturn, !sentReturn {
                try input.fileHandleForWriting.write(contentsOf: Data("\n".utf8))
                sentReturn = true
            }
            if !child.isRunning, count <= 0 { return output }
            try await Task.sleep(for: .milliseconds(100))
        }
    }
}
