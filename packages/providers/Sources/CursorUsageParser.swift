// Adapted from CodexBar's CursorStatusProbe.swift; see Resources/CodexBarAttribution.txt.
import Foundation
import RationsCore

enum CursorUsageParser {
    static func parse(_ data: Data, profile: AccountProfile, now: Date) throws -> AccountReading {
        let root = try ProviderJSON(data)
        guard let membership = root.string("membershipType"),
              root.object("individualUsage") != nil || root.object("teamUsage") != nil else {
            throw ProviderFailure.invalidResponse
        }
        let individual = root.object("individualUsage")
        let plan = individual?.object("plan")
        let team = root.object("teamUsage")
        let reset = ProviderJSON.date(root.string("billingCycleEnd"))
        let lanes = ["autoPercentUsed", "apiPercentUsed"].map { percentage(plan?.number($0)) }
        let knownLanes = lanes.compactMap { $0 }
        let laneAverage = knownLanes.isEmpty ? nil : knownLanes.reduce(0, +) / Double(knownLanes.count)
        let total = percentage(plan?.number("totalPercentUsed")) ?? laneAverage ?? ratio(plan)
            ?? ratio(individual?.object("overall")) ?? ratio(team?.object("pooled"))
        var rows = [row(id: "main", label: "Monthly total", percent: total, reset: reset)]
        for (index, label) in ["Cursor Models", "Other Models"].enumerated() where plan?.values[
            index == 0 ? "autoPercentUsed" : "apiPercentUsed"
        ] != nil {
            rows.append(row(id: "pool-\(index)", label: label, percent: lanes[index], reset: reset))
        }
        var profile = profile
        profile.plan = membership.capitalized
        var reading = AccountReading(profile: profile, rows: rows, fetchedAt: now)
        let spending = extraUsage(individual?.object("onDemand")) ?? extraUsage(team?.object("onDemand"))
        let unknown = total == nil ? "Cursor did not report a monthly allowance." : nil
        reading.notice = [unknown, spending].compactMap { $0 }.joined(separator: " ")
        if reading.notice?.isEmpty == true { reading.notice = nil }
        return reading
    }

    private static func row(id: String, label: String, percent: Double?, reset: Date?) -> QuotaRow {
        QuotaRow(id: id, windows: [
            QuotaWindow(id: id, label: label, usedPercent: percent, resetsAt: reset, period: .monthly)
        ], isSupplemental: id != "main")
    }

    private static func percentage(_ value: Double?) -> Double? {
        guard let value, value >= 0 else { return nil }
        return min(100, value)
    }

    private static func ratio(_ value: ProviderJSON?) -> Double? {
        guard value?.bool("enabled") != false, let used = value?.number("used"), used >= 0,
              let limit = value?.number("limit"), limit > 0 else { return nil }
        return percentage(used / limit * 100)
    }

    private static func extraUsage(_ value: ProviderJSON?) -> String? {
        guard value?.bool("enabled") == true, let used = value?.number("used"), used >= 0 else { return nil }
        let spent = (used / 100).formatted(.currency(code: "USD"))
        if let limit = value?.number("limit"), limit > 0 {
            return "Extra usage: \(spent) of \((limit / 100).formatted(.currency(code: "USD"))) monthly limit."
        }
        return "Extra usage this month: \(spent)."
    }
}
