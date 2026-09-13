import Darwin
import Foundation

enum ClaudeTerminalProbe {
    static func read() async throws -> String {
        let task = Task.detached(priority: .utility) { try capture() }
        return try await withTaskCancellationHandler {
            try await task.value
        } onCancel: { task.cancel() }
    }

    private static func capture() throws -> String {
        var controllerFD: Int32 = -1
        var terminalFD: Int32 = -1
        var size = winsize(ws_row: 60, ws_col: 180, ws_xpixel: 0, ws_ypixel: 0)
        guard openpty(&controllerFD, &terminalFD, nil, nil, &size) == 0 else { throw ProviderFailure.timedOut }
        defer { close(controllerFD) }
        let terminal = FileHandle(fileDescriptor: terminalFD, closeOnDealloc: true)
        let process = Process()
        process.executableURL = try VendorExecutable.locate(.claude)
        process.arguments = ["--safe-mode"]
        process.currentDirectoryURL = try VendorProcess.runtimeDirectory()
        process.standardInput = terminal
        process.standardOutput = terminal
        process.standardError = terminal
        try process.run()
        ProviderProcesses.shared.add(process)
        try terminal.close()
        defer { VendorProcess.stop(process); ProviderProcesses.shared.remove(process) }
        _ = fcntl(controllerFD, F_SETFL, O_NONBLOCK)
        return try readScreen(controllerFD: controllerFD, process: process)
    }

    private static func readScreen(controllerFD: Int32, process: Process) throws -> String {
        let deadline = Date.now.addingTimeInterval(25)
        var data = Data()
        var commandSent = false
        var trusted = false
        var cursorReplies = 0
        var snapshot = ""
        var lastOutput = Date.now
        var buffer = [UInt8](repeating: 0, count: 65_536)
        while process.isRunning, Date.now < deadline {
            try Task.checkCancellation()
            let count = Darwin.read(controllerFD, &buffer, buffer.count)
            if count <= 0 {
                if ready(snapshot), Date.now.timeIntervalSince(lastOutput) >= 0.2 { return snapshot }
                Thread.sleep(forTimeInterval: 0.1)
                continue
            }
            data.append(contentsOf: buffer.prefix(count))
            lastOutput = .now
            guard data.count < 1_000_000 else { throw ProviderFailure.invalidResponse }
            guard let raw = String(data: data, encoding: .utf8) else {
                Thread.sleep(forTimeInterval: 0.1)
                continue
            }
            var screen = TerminalScreen()
            screen.consume(data)
            let text = screen.text
            snapshot = text
            respondToTerminal(controllerFD, raw: raw, text: text, trusted: &trusted, cursorReplies: &cursorReplies)
            if !commandSent, text.contains("❯"), !text.contains("trust this folder"),
               text.contains("Claude Code") {
                send("/usage\r", to: controllerFD)
                commandSent = true
            }
            Thread.sleep(forTimeInterval: 0.1)
        }
        throw ProviderFailure.unavailable(
            "Claude usage could not be read. Open Claude Code and run /usage, then reconnect."
        )
    }

    private static func ready(_ text: String) -> Bool {
        text.localizedCaseInsensitiveContains("current week") && text.components(separatedBy: "% used").count >= 3
    }

    private static func respondToTerminal(
        _ descriptor: Int32, raw: String, text: String, trusted: inout Bool, cursorReplies: inout Int
    ) {
        let requests = raw.components(separatedBy: "\u{1B}[6n").count - 1
        if requests > cursorReplies { send("\u{1B}[1;1R", to: descriptor); cursorReplies = requests }
        if !trusted, text.localizedCaseInsensitiveContains("trust this folder") {
            send("\u{1B}[B\r", to: descriptor)
            trusted = true
        }
    }

    private static func send(_ text: String, to descriptor: Int32) {
        let bytes = Array(text.utf8)
        _ = bytes.withUnsafeBytes { Darwin.write(descriptor, $0.baseAddress, $0.count) }
    }
}
