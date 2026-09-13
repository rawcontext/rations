import RationsCore

struct AccountFetchResult: Sendable {
    let id: String
    let reading: AccountReading?
    let failure: ProviderFailure?

    static func fetch(_ account: AccountConnection, using fetcher: ProviderFetcher) async -> Self {
        do { return Self(id: account.profile.id, reading: try await fetcher.fetch(account), failure: nil) } catch {
            let failure = error as? ProviderFailure
                ?? .unavailable("Couldn't reach the provider. Try refreshing again.")
            return Self(id: account.profile.id, reading: nil, failure: failure)
        }
    }
}
