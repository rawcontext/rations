import Foundation

public struct QuotaWindow: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let usedPercent: Double?
    public let resetsAt: Date?
    public let period: QuotaPeriod

    public init(
        id: String, label: String, usedPercent: Double?, resetsAt: Date?, period: QuotaPeriod = .weekly
    ) {
        self.id = id
        self.label = label
        self.usedPercent = usedPercent.flatMap { value in
            value.isFinite && (0...100).contains(value) ? value : nil
        }
        self.resetsAt = resetsAt
        self.period = period
    }

    public var remainingPercent: Double? {
        usedPercent.map { 100 - $0 }
    }
}
