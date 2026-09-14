public enum ProviderID: String, CaseIterable, Codable, Identifiable, Sendable {
    case codex
    case claude
    case antigravity
    case grok
    case cursor

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .codex: "Codex"
        case .claude: "Claude"
        case .antigravity: "Antigravity"
        case .grok: "Grok"
        case .cursor: "Cursor"
        }
    }
}
