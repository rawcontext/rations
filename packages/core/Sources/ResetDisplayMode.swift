public enum ResetDisplayMode: String, Codable, CaseIterable, Sendable {
    case absolute
    case relative
    case both

    public var title: String { rawValue.capitalized }
}
