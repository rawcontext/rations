import RationsCore
import SwiftUI

struct AccountDetailView: View {
    let account: AccountReading
    let row: QuotaRow
    let preferences: DisplayPreferences

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(account.profile.name).fontWeight(.semibold)
                Text([account.profile.plan, account.profile.displayEmail(redacted: preferences.hidePersonalInformation)]
                    .compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 11)).foregroundStyle(.secondary)
            }
            ForEach(row.windows) { window in
                WindowDetailView(window: window, preferences: preferences)
            }
            Text(creditsText + " · Updated " + ResetText.age(of: account.fetchedAt, now: .now))
                .font(.system(size: 11)).foregroundStyle(.secondary)
            if !account.isFresh(at: .now) {
                Text("Stale data · refresh to verify").font(.system(size: 11)).foregroundStyle(.secondary)
            }
        }
        .font(.system(size: 13)).padding(10).frame(width: 336, alignment: .leading)
    }

    private var creditsText: String {
        guard let count = account.resetCredits else { return "Reset credits unavailable" }
        return count == 0 ? "No reset credits" : "\(count) reset credits (read-only)"
    }
}
