import AppKit
import RationsCore
import SwiftUI

final class AccountMenuItemView: NSView {
    private let hosting: NSHostingView<AccountMenuRow>

    init(content: AccountMenuRow) {
        hosting = NSHostingView(rootView: content)
        super.init(frame: NSRect(x: 0, y: 0, width: 344, height: 24))
        hosting.frame = bounds
        addSubview(hosting)
        setAccessibilityElement(true)
        setAccessibilityRole(.menuItem)
        setAccessibilityLabel(content.row.label ?? content.account.profile.name)
        setAccessibilityValue(content.row.windows.map { window in
            let percent = content.preferences.usageMode.percent(for: window).map { "\(Int($0.rounded()))%" }
                ?? "unknown"
            return window.label + ": " + percent + " " + content.preferences.usageMode.title.lowercased()
                + ", " + ResetText.countdown(to: window.resetsAt, now: .now)
        }.joined(separator: "; "))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Account menu items are created programmatically") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    func setHighlighted(_ highlighted: Bool) {
        hosting.rootView.highlighted = highlighted
    }
}
