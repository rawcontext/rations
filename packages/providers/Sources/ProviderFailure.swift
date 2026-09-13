import Foundation
import Security

public enum ProviderFailure: Error, LocalizedError, Sendable {
    case notSignedIn(String)
    case unavailable(String)
    case invalidResponse
    case rateLimited(Date)
    case timedOut
    case keychain(Int32)

    var needsKeychainApproval: Bool {
        guard case let .keychain(status) = self else { return false }
        return status == errSecInteractionNotAllowed || status == errSecAuthFailed
    }

    public var errorDescription: String? {
        switch self {
        case let .notSignedIn(hint), let .unavailable(hint): hint
        case .invalidResponse: "The provider returned an unrecognized usage response."
        case let .rateLimited(date):
            "The provider requested a cooldown until \(date.formatted(date: .omitted, time: .shortened))."
        case .timedOut: "The provider did not respond in time. Try refreshing again."
        case let .keychain(status) where status == errSecInteractionNotAllowed || status == errSecAuthFailed:
            "Keychain access needs approval. Use the account connection controls in Settings to allow access."
        case let .keychain(status): "Rations could not access Keychain (\(status))."
        }
    }
}
