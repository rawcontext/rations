import RationsCore

struct AccountFetchResult: Sendable {
    let connection: AccountConnection
    var id: String { connection.profile.id }
    let reading: AccountReading?
    let failure: ProviderFailure?

    static func fetch(
        _ account: AccountConnection, request: @Sendable (AccountConnection) async throws -> AccountReading,
        recover: @Sendable (AccountConnection) async throws -> AccountConnection = AccountCredentialRecovery.capture
    ) async -> Self {
        var current = account
        do {
            let reading: AccountReading
            do { reading = try await request(current) } catch let error as ProviderFailure {
                guard case .notSignedIn = error else { throw error }
                let renewed = try await recover(current)
                try AccountCredentialRecovery.validate(renewed, for: current)
                try Task.checkCancellation()
                current = renewed
                reading = try await request(current)
            }
            return Self(connection: current, reading: reading, failure: nil)
        } catch {
            let failure = error as? ProviderFailure
                ?? .unavailable("Couldn't reach the provider. Try refreshing again.")
            return Self(connection: current, reading: nil, failure: failure)
        }
    }
}
