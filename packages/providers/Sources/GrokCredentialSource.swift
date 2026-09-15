import Foundation

struct GrokCredentialSource {
    var read: () throws -> Data
    var renew: () async throws -> Void = {
        _ = try await VendorProcess.run(try VendorExecutable.locate(.grok), arguments: ["models"])
    }

    func capture(now: Date = .now, forceRenewal: Bool = false) async throws -> Data {
        try Task.checkCancellation()
        let current = try read()
        let expiresSoon = try Self.expiry(current).map { $0 <= now.addingTimeInterval(60) } ?? false
        guard forceRenewal || expiresSoon else { return current }
        try await renew()
        try Task.checkCancellation()
        let updated = try read()
        if let expiry = try Self.expiry(updated), expiry <= now {
            throw ProviderFailure.notSignedIn("Grok could not renew this sign-in. Open Grok and sign in again.")
        }
        return updated
    }

    private static func expiry(_ data: Data) throws -> Date? {
        let entry = try CredentialDiscovery.grokEntry(data)
        if let date = ProviderJSON.date(entry.string("expires_at")) { return date }
        return ProviderJSON.claims(entry.string("key"))?.number("exp").map(Date.init(timeIntervalSince1970:))
    }
}
