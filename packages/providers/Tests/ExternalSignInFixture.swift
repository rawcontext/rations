@testable import RationsProviders

actor ExternalSignInFixture {
    private var responses: [Result<AccountConnection, ProviderFailure>]
    private(set) var interactionRequests: [Bool] = []
    private(set) var browserOpened = false

    init(_ responses: [Result<AccountConnection, ProviderFailure>]) { self.responses = responses }

    func capture(interactive: Bool) throws -> AccountConnection {
        interactionRequests.append(interactive)
        guard !responses.isEmpty else { throw ProviderFailure.invalidResponse }
        return try responses.removeFirst().get()
    }

    func openBrowser() { browserOpened = true }
}
