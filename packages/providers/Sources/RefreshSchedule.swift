import Foundation
import RationsCore

struct RefreshSchedule {
    private var nextPoll: [ProviderID: Date] = [:]
    private var retryAfter: [ProviderID: Date] = [:]

    mutating func reserve(_ enabled: Set<ProviderID>, now: Date, manual: Bool = false) -> Set<ProviderID> {
        let due = enabled.filter {
            (retryAfter[$0] ?? .distantPast) <= now && (manual || (nextPoll[$0] ?? .distantPast) <= now)
        }
        for provider in due { nextPoll[provider] = now.addingTimeInterval(60) }
        return due
    }

    mutating func postpone(_ provider: ProviderID, until date: Date) {
        retryAfter[provider] = max(retryAfter[provider] ?? .distantPast, date)
    }
}
