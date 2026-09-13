import Darwin
import Foundation
@testable import RationsProviders
import Testing

struct LoginProcessTests {
    @Test
    func waitsForLoginCompletionAndHandlesBrowserPrompt() async throws {
        let fixture = try LoginFixture(script: """
        printf 'press ENTER to open in browser\nhttps://auth.openai.com/oauth/authorize?state=fixture\n'
        read -r line
        printf done > completed
        """)
        defer { fixture.cleanUp() }
        try await LoginProcess.run(fixture.command, progress: { _ in }, timeout: .seconds(5))
        let marker = try String(contentsOf: fixture.directory.appendingPathComponent("completed"), encoding: .utf8)
        #expect(marker == "done")
    }

    @Test
    func rejectsFailedLoginWithoutReturningSensitiveOutput() async throws {
        let fixture = try LoginFixture(script: "echo 'private-fixture-token'; exit 1")
        defer { fixture.cleanUp() }
        do {
            try await LoginProcess.run(fixture.command, progress: { _ in })
            Issue.record("Expected sign-in failure")
        } catch {
            #expect(error is ProviderFailure)
            #expect(!error.localizedDescription.contains("private-fixture-token"))
        }
    }

    @Test
    func cancellationStopsTheOwnedLoginProcess() async throws {
        let fixture = try LoginFixture(script: "echo $$ > pid; read -r line")
        defer { fixture.cleanUp() }
        let task = Task { try await LoginProcess.run(fixture.command, progress: { _ in }) }
        let pidFile = fixture.directory.appendingPathComponent("pid")
        try await SignInTestWait.until { FileManager.default.fileExists(atPath: pidFile.path) }
        let pidText = try String(contentsOf: pidFile, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
        let processID = try #require(Int32(pidText))
        task.cancel()
        await #expect(throws: CancellationError.self) { try await task.value }
        try await SignInTestWait.until { kill(processID, 0) != 0 }
    }

    @Test
    func abandonedBrowserLoginTimesOut() async throws {
        let fixture = try LoginFixture(script: "read -r line")
        defer { fixture.cleanUp() }
        await #expect(throws: ProviderFailure.self) {
            try await LoginProcess.run(fixture.command, progress: { _ in }, timeout: .milliseconds(100))
        }
    }
}
