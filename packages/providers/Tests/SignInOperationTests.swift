import Foundation
@testable import RationsProviders
import Testing

@MainActor
struct SignInOperationTests {
    @Test
    func successCompletesAutomaticallyAndIgnoresRepeatedClicks() async throws {
        let operation = SignInOperation()
        let gate = SignInTestGate()
        var calls = 0
        operation.start { progress in
            calls += 1
            progress(.waitingForBrowser(nil))
            await gate.wait()
            progress(.connecting)
        }
        operation.start { _ in calls += 1 }
        #expect(operation.isRunning)
        #expect(!operation.completed)
        await gate.release()
        try await SignInTestWait.until { operation.completed }
        #expect(calls == 1)
        #expect(!operation.isRunning)
        #expect(operation.error == nil)
    }

    @Test
    func cancellationRejectsLateProgressAndSuccess() async throws {
        let operation = SignInOperation()
        let gate = SignInTestGate()
        operation.start { progress in
            await gate.wait()
            progress(.connecting)
        }
        operation.cancel()
        await gate.release()
        operation.start { _ in throw ProviderFailure.unavailable("Retry sign-in") }
        try await SignInTestWait.until { operation.error != nil }
        #expect(operation.error == "Retry sign-in")
        #expect(!operation.completed)
        #expect(operation.progress == .starting)
    }
}
