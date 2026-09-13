import Foundation
import Testing

@MainActor
enum SignInTestWait {
    static func until(_ condition: () -> Bool) async throws {
        for _ in 0..<200 {
            if condition() { return }
            try await Task.sleep(for: .milliseconds(10))
        }
        Issue.record("Timed out waiting for isolated sign-in test")
    }
}
