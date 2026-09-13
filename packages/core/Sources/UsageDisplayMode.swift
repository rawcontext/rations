public enum UsageDisplayMode: String, Codable, CaseIterable, Sendable {
    case remaining
    case used

    public var title: String { self == .remaining ? "Left" : "Used" }

    public func percent(for window: QuotaWindow) -> Double? {
        self == .remaining ? window.remainingPercent : window.usedPercent
    }
}
