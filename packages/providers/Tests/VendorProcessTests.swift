import Foundation
@testable import RationsProviders
import Testing

struct VendorProcessTests {
    @Test
    func timeoutInterruptsACommandWithNoOutput() async throws {
        let fixture = try LoginFixture(script: "while :; do :; done")
        defer { fixture.cleanUp() }
        do {
            _ = try await VendorProcess.run(
                fixture.executable, arguments: [], timeout: 0.1, directory: fixture.directory
            )
            Issue.record("Expected timeout")
        } catch let error as ProviderFailure {
            guard case .timedOut = error else { Issue.record("Wrong timeout error"); return }
        }
    }

    @Test
    func callerCancellationStopsTheCommand() async throws {
        let fixture = try LoginFixture(script: "echo started > marker; while :; do :; done")
        defer { fixture.cleanUp() }
        let task = Task {
            try await VendorProcess.run(fixture.executable, arguments: [], directory: fixture.directory)
        }
        let marker = fixture.directory.appendingPathComponent("marker")
        try await SignInTestWait.until { FileManager.default.fileExists(atPath: marker.path) }
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
    }

    @Test
    func backgroundChildHoldingStdoutDoesNotHoldUpTheResult() async throws {
        let fixture = try LoginFixture(script: "printf complete; /bin/sleep 1 &\nexit 0")
        defer { fixture.cleanUp() }
        let result = try await VendorProcess.run(
            fixture.executable, arguments: [], timeout: 0.5, directory: fixture.directory
        )
        #expect(String(data: result, encoding: .utf8) == "complete")
    }
}
