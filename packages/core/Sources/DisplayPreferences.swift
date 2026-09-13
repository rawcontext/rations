public struct DisplayPreferences: Codable, Equatable, Sendable {
    public var usageMode = UsageDisplayMode.remaining
    public var resetMode = ResetDisplayMode.both
    public var menuProvider: ProviderID?
    public var warningRemaining = 25
    public var criticalRemaining = 10
    public var refreshMinutes = 5
    public var hidePersonalInformation = true
    public var disabledProviders: Set<ProviderID> = []

    public init() {}

    public mutating func normalize() {
        criticalRemaining = min(99, max(0, criticalRemaining))
        warningRemaining = min(100, max(criticalRemaining + 1, warningRemaining))
        refreshMinutes = min(15, max(2, refreshMinutes))
    }

    public func tone(for window: QuotaWindow) -> UsageTone {
        guard let remaining = window.remainingPercent else { return .unknown }
        if remaining <= Double(criticalRemaining) { return .critical }
        if remaining <= Double(warningRemaining) { return .warning }
        return .comfortable
    }
}
