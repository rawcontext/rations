public struct QuotaRow: Identifiable, Codable, Equatable, Sendable {
    public let id: String
    public let label: String?
    public let windows: [QuotaWindow]
    public let isSupplemental: Bool

    public init(id: String, windows: [QuotaWindow], label: String? = nil, isSupplemental: Bool = false) {
        self.id = id
        self.label = label
        self.windows = windows
        self.isSupplemental = isSupplemental
    }

    public var tightestWindow: QuotaWindow? {
        windows.filter { $0.usedPercent != nil }.max { ($0.usedPercent ?? 0) < ($1.usedPercent ?? 0) }
    }

    public var resetWindow: QuotaWindow? {
        tightestWindow ?? windows.filter { $0.resetsAt != nil }.min {
            ($0.resetsAt ?? .distantFuture) < ($1.resetsAt ?? .distantFuture)
        }
    }

    public func window(for period: QuotaPeriod) -> QuotaWindow? {
        windows.first { $0.period == period }
    }
}
