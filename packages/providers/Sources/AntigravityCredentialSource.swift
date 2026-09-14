import Foundation

struct AntigravityCredentialSource {
    var read: (Bool) throws -> Data = { interactive in
        guard let stored = try NativeKeychain.read(
            service: "gemini", account: "antigravity", interactive: interactive
        ).first else {
            throw ProviderFailure.notSignedIn("Sign in with Antigravity or agy, then connect the account.")
        }
        return NativeKeychain.unwrapGoKeyring(stored)
    }
    var renew: () async throws -> Void = {
        _ = try await VendorProcess.run(try VendorExecutable.locate(.antigravity), arguments: ["models"])
    }

    func capture(interactive: Bool, now: Date = .now) async throws -> Data {
        try Task.checkCancellation()
        let existing = try existingCredential(interactive: interactive)
        if let existing {
            let expiry = try ProviderJSON(existing).object("token")?.string("expiry").flatMap(ProviderJSON.date)
            guard let expiry, expiry <= now.addingTimeInterval(60) else { return existing }
        }
        // Renew before requesting access: the vendor may replace its Keychain item.
        try await renew()
        try Task.checkCancellation()
        return try read(interactive)
    }

    private func existingCredential(interactive: Bool) throws -> Data? {
        do {
            return try read(false)
        } catch let error as ProviderFailure where interactive && error.needsKeychainApproval {
            return nil
        }
    }
}
