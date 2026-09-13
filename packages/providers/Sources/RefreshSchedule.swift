import Foundation
import RationsCore

struct RefreshSchedule {
    private var deadlines: [ProviderID: Date] = [:]

    mutating func reserve(_ enabled: Set<ProviderID>, now: Date) -> Set<ProviderID> {
        let due = enabled.filter { (deadlines[$0] ?? .distantPast) <= now }
        for provider in due { deadlines[provider] = now.addingTimeInterval(60) }
        return due
    }

    mutating func postpone(_ provider: ProviderID, until date: Date) {
        deadlines[provider] = max(deadlines[provider] ?? .distantPast, date)
    }
}
