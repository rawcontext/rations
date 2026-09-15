public enum ConnectionIssue: String, Codable, Sendable {
    case verifying
    case authentication
    case approval
    case cooldown
    case unavailable

    public var label: String {
        switch self {
        case .verifying: "Checking…"
        case .authentication: "Sign-in required"
        case .approval: "Access required"
        case .cooldown: "Cooling down"
        case .unavailable: "Refresh failed"
        }
    }

    public var requiresReconnect: Bool { self == .authentication || self == .approval }
}
