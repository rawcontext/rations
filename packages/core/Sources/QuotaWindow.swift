import Foundation

public struct QuotaWindow: Equatable, Identifiable, Sendable {
    public let id: String
    public let label: String
    public let usedPercent: Double?
    public let resetsAt: Date?

    public init(id: String, label: String, usedPercent: Double?, resetsAt: Date?) {
        self.id = id
        self.label = label
        self.usedPercent = usedPercent.flatMap { value in
            value.isFinite && (0...100).contains(value) ? value : nil
        }
        self.resetsAt = resetsAt
    }

    public var remainingPercent: Double? {
        usedPercent.map { 100 - $0 }
    }
}
