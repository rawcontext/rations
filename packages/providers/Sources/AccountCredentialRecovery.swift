import Foundation

enum AccountCredentialRecovery {
    static func capture(_ saved: AccountConnection) async throws -> AccountConnection {
        let provider = saved.profile.provider
        var native = try await CredentialDiscovery.capture(provider)
        try validate(native, for: saved)
        if native.credential == saved.credential, !native.usesClaudeCLI {
            native = try await CredentialDiscovery.capture(provider, forceRenewal: true)
            try validate(native, for: saved)
        }
        guard native.credential != saved.credential || native.usesClaudeCLI else {
            throw ProviderFailure.notSignedIn("The vendor could not renew this sign-in. Reconnect this account.")
        }
        return native
    }

    static func validate(_ renewed: AccountConnection, for saved: AccountConnection) throws {
        guard renewed.profile.id == saved.profile.id, renewed.profile.provider == saved.profile.provider else {
            throw ProviderFailure.notSignedIn(
                "The vendor is signed in to a different account. Reconnect this saved account to refresh it."
            )
        }
    }
}
