import AppKit
import Observation
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
        observeAccessibility()
    }

    private func observeAccessibility() {
        withObservationTracking {
            let content = hosting.rootView
            setAccessibilityLabel(content.account.profile.name)
            let state = content.account.isFresh(at: content.store.displayTime) ? "" : "; stale usage"
            setAccessibilityValue(accessibilitySummary(content) + state)
        } onChange: { [weak self] in
            Task { @MainActor in self?.observeAccessibility() }
        }
    }

    private func accessibilitySummary(_ content: AccountMenuRow) -> String {
        content.row.windows.map { window in
            let percent = content.preferences.usageMode.percent(for: window).map { "\(Int($0.rounded()))%" }
                ?? "unknown"
            let usage = window.label + ": " + percent + " " + content.preferences.usageMode.title.lowercased()
            let countdown = ResetText.countdown(to: window.resetsAt, now: content.store.displayTime)
            return countdown.isEmpty ? usage : usage + ", " + countdown
        }.joined(separator: "; ")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("Account menu items are created programmatically") }

    override func hitTest(_ point: NSPoint) -> NSView? { frame.contains(point) ? self : nil }

    // Account rows open submenus through menu tracking; clicks have no action.
    override func mouseDown(with event: NSEvent) {}
    override func mouseUp(with event: NSEvent) {}

    func setHighlighted(_ highlighted: Bool) {
        hosting.rootView.highlighted = highlighted
    }
}
