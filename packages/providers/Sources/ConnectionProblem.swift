import RationsCore

public struct ConnectionProblem: Equatable, Sendable {
    public let message: String
    public let kind: ConnectionIssue

    init(_ error: Error) {
        message = LiveAccountService.message(error)
        kind = (error as? ProviderFailure)?.kind ?? .unavailable
    }
}
