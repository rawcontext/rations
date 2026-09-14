import RationsCore
import SwiftUI

struct AccountMenuRow: View {
    let initialAccount: AccountReading
    let store: RationsStore
    var highlighted = false

    var account: AccountReading { store.accounts.first { $0.id == initialAccount.id } ?? initialAccount }
    var row: QuotaRow { account.menuRow }
    var preferences: DisplayPreferences { store.preferences }
    private var active: Bool { store.isActive(account) }

    private var textColor: Color { highlighted ? .white : .primary }
    private var tone: UsageTone {
        guard account.isFresh(at: store.displayTime) else { return .stale }
        return row.tightestWindow.map { preferences.tone(for: $0) } ?? .unknown
    }

    var body: some View {
        HStack(spacing: 8) {
            Circle().fill(active ? (highlighted ? .white : Color.accentColor) : .clear)
                .frame(width: 5, height: 5)
            Text(account.profile.name)
                .foregroundStyle(textColor)
                .lineLimit(1).truncationMode(.tail).frame(width: 82, alignment: .leading)
            meters
            Text(ResetText.countdown(to: row.resetWindow?.resetsAt, now: store.displayTime))
                .font(.system(size: 11.5).monospacedDigit())
                .foregroundStyle(highlighted ? .white : tone.color)
                .frame(width: 56, alignment: .trailing).lineLimit(1).minimumScaleFactor(0.8)
            Text(account.resetCredits.map(String.init) ?? "")
                .font(.system(size: 11.5).monospacedDigit())
                .foregroundStyle(textColor.opacity(account.resetCredits == 0 ? 0.55 : 1))
                .frame(width: 16, alignment: .trailing)
            Image(systemName: "chevron.right").font(.system(size: 8, weight: .semibold))
                .foregroundStyle(textColor.opacity(0.45)).frame(width: 7)
        }
        .font(.system(size: 13)).padding(.horizontal, 10)
        .frame(width: 344, height: 24, alignment: .leading)
        .background(highlighted ? Color.accentColor : .clear, in: RoundedRectangle(cornerRadius: 7))
    }

    private var meters: some View {
        VStack(spacing: 3) {
            if let monthly = row.window(for: .monthly) {
                QuotaMeter(window: monthly, preferences: preferences, highlighted: highlighted)
            } else {
                QuotaMeter(window: row.window(for: .session), preferences: preferences, highlighted: highlighted)
                QuotaMeter(window: row.window(for: .weekly), preferences: preferences, highlighted: highlighted)
            }
        }
        .frame(width: 108).opacity(account.isFresh(at: store.displayTime) ? 1 : 0.45)
    }
}
