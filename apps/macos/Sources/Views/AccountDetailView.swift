import RationsCore
import SwiftUI

struct AccountDetailView: View {
    let initialAccount: AccountReading
    let store: RationsStore

    private var account: AccountReading { store.accounts.first { $0.id == initialAccount.id } ?? initialAccount }
    private var preferences: DisplayPreferences { store.preferences }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(account.profile.name).fontWeight(.semibold)
                Text([account.profile.plan, account.profile.displayEmail(redacted: preferences.hidePersonalInformation)]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            quotaGroups.opacity(account.isFresh(at: store.displayTime) ? 1 : 0.45)
            Text(freshnessText)
                .font(.system(size: 11)).foregroundStyle(.secondary)
            if let error = account.error {
                Text(error).font(.system(size: 11)).foregroundStyle(.secondary)
            } else if !account.isFresh(at: store.displayTime) {
                Text("Stale data · refresh to verify").font(.system(size: 11)).foregroundStyle(.secondary)
            }
            if let notice = account.notice { Text(notice).font(.system(size: 11)).foregroundStyle(.secondary) }
        }
        .font(.system(size: 13)).padding(10).frame(width: 336, alignment: .leading)
    }

    private var quotaGroups: some View {
        ForEach(account.rows) { row in
            VStack(alignment: .leading, spacing: 10) {
                if let label = row.label {
                    Divider()
                    Text(label).font(.system(size: 12, weight: .semibold))
                }
                ForEach(row.windows) { window in
                    WindowDetailView(window: window, preferences: preferences, now: store.displayTime)
                }
            }
        }
    }

    private var freshnessText: String {
        guard account.fetchedAt != nil else { return "Usage not yet available" }
        let updated = "Updated " + ResetText.age(of: account.fetchedAt, now: store.displayTime)
        guard let count = account.resetCredits else { return updated }
        return "\(count) " + (count == 1 ? "reset" : "resets") + " · " + updated
    }
}
