import Foundation
import RationsCore
import Testing

struct AggregateQuotaTests {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test
    func averagesAccountsAcrossProviders() {
        let readings = [reading(.codex, pools: [[100, 20]]), reading(.claude, pools: [[0, 0]])]
        let aggregate = AggregateQuota.summarize(readings, now: now)
        #expect(aggregate.remainingPercent == 50)
        #expect(aggregate.reportingAccountCount == 2)
    }

    @Test
    func countsEveryAccountWithinTheSameProvider() throws {
        let readings = [reading(.codex, pools: [[0]], accountID: "lab"),
                        reading(.codex, pools: [[100]], accountID: "acme"), reading(.claude, pools: [[0]])]
        let aggregate = AggregateQuota.summarize(readings, now: now)
        let remaining = try #require(aggregate.remainingPercent)
        #expect(abs(remaining - 200.0 / 3) < 0.0001)
        #expect(aggregate.reportingAccountCount == 3)
    }

    @Test
    func independentPoolsDoNotGiveAnAccountMoreWeight() {
        let readings = [reading(.antigravity, pools: [[0, 0], [100, 0]]), reading(.grok, pools: [[0]])]
        #expect(AggregateQuota.summarize(readings, now: now).remainingPercent == 75)
    }

    @Test
    func ignoresSupplementalConstraintsAsSeparateCapacity() {
        var account = reading(.claude, pools: [[20, 40]])
        account = AccountReading(profile: account.profile, rows: account.rows + [
            QuotaRow(id: "opus", windows: [window(100)], isSupplemental: true)
        ], fetchedAt: account.fetchedAt)
        #expect(AggregateQuota.summarize([account], now: now).remainingPercent == 60)
    }

    @Test
    func excludesMissingAndStaleAccountsWithoutInventingZero() {
        let accounts = [reading(.codex, pools: [[100]], age: 1200), reading(.claude, pools: [[nil]]),
                        reading(.grok, pools: [[20]])]
        let aggregate = AggregateQuota.summarize(accounts, now: now)
        #expect(aggregate.remainingPercent == 80)
        #expect(aggregate.pendingAccountCount == 2)
    }

    @Test
    func keepsOnlyNewestReadingForEachAccount() {
        let accounts = [reading(.codex, pools: [[100]], age: 120), reading(.codex, pools: [[20]], age: 30)]
        let aggregate = AggregateQuota.summarize(accounts, now: now)
        #expect(aggregate.remainingPercent == 80)
        #expect(aggregate.totalAccountCount == 1)
    }

    @Test
    func drainsAndConfirmedResetsChangeTheAggregate() {
        let states = [0.0, 60, 100, 0].map { reading(.codex, pools: [[$0]]) }
        let values = states.map { AggregateQuota.summarize([$0], now: now).remainingPercent }
        #expect(values == [100, 40, 0, 100])
    }

    @Test
    func expiresAtResetWithoutAssumingRefill() {
        let account = reading(.codex, pools: [[100]])
        let before = AggregateQuota.summarize([account], now: now)
        let after = AggregateQuota.summarize([account], now: now.addingTimeInterval(600))
        #expect(before.nextUpdateAt == now.addingTimeInterval(600))
        #expect(after.remainingPercent == nil)
        #expect(after.pendingAccountCount == 1)
    }

    @Test
    func unknownWindowsAndIndependentPoolsRemainIncomplete() {
        let account = reading(.antigravity, pools: [[20], [0, nil]])
        #expect(AggregateQuota.summarize([account], now: now).remainingPercent == nil)
        #expect(AggregateQuota.summarize([], now: now).totalAccountCount == 0)
    }

    private func reading(
        _ provider: ProviderID, pools: [[Double?]], age: Double = 60, accountID: String = "personal"
    ) -> AccountReading {
        AccountReading(
            profile: AccountProfile(id: accountID, provider: provider, name: "Test", plan: nil, email: nil),
            rows: pools.enumerated().map { index, values in
                QuotaRow(id: String(index), windows: values.map(window))
            },
            fetchedAt: now.addingTimeInterval(-age)
        )
    }

    private func window(_ used: Double?) -> QuotaWindow {
        QuotaWindow(id: "quota", label: "Quota", usedPercent: used, resetsAt: now.addingTimeInterval(600))
    }
}
