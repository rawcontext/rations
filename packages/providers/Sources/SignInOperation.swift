import Foundation
import Observation

@preconcurrency @MainActor @Observable
public final class SignInOperation {
    public private(set) var isRunning = false
    public private(set) var completed = false
    public private(set) var progress = SignInProgress.starting
    public private(set) var error: String?
    private var task: Task<Void, Never>?
    private var attempt: UUID?

    public init() {}

    @preconcurrency public func start(
        _ action: @escaping @MainActor (@escaping @Sendable (SignInProgress) -> Void) async throws -> Void
    ) {
        guard !isRunning else { return }
        let id = UUID()
        attempt = id
        isRunning = true
        completed = false
        progress = .starting
        error = nil
        task = Task { [weak self] in
            do {
                try await action { [weak self] value in
                    Task { @MainActor in
                        guard self?.attempt == id else { return }
                        self?.progress = value
                    }
                }
                try Task.checkCancellation()
                if self?.attempt == id { self?.completed = true }
            } catch is CancellationError {
                // Cancellation leaves the sheet without presenting an error.
            } catch {
                if self?.attempt == id { self?.error = LiveAccountService.message(error) }
            }
            self?.finish(id)
        }
    }

    private func finish(_ id: UUID) {
        guard attempt == id else { return }
        isRunning = false
        attempt = nil
        task = nil
    }

    public func cancel() {
        attempt = nil
        task?.cancel()
        task = nil
        isRunning = false
    }
}
