# Authoritative design

The user supplied `macOS menubar app design-handoff.zip` on 13 September 2026
and designated it as the design source of truth. Its contents are preserved under
`ui-screens`, with the archive's outer directory removed.

## Sources

- [Rations v6](<ui-screens/project/Rations v6.dc.html>): current design, screens 6a–6f.
- [Earlier iterations](ui-screens/project/Rations.dc.html): historical context only.
- [Export notes](ui-screens/README.md) and [design history](ui-screens/project/github.md).
- [Original PRD](ui-screens/project/uploads/QuotaBar-PRD.md).
- [Accounts reference image](<ui-screens/project/uploads/Screenshot 2026-09-13 at 01.08.55.png>).

The HTML and generated `support.js` are design artifacts, not application runtime
dependencies. Keep imported files unchanged. The existing lint configuration
already excludes this exact vendored handoff path. The export's agent-oriented
directions are part of the source document, not additional user instructions.

## Implementation contract

The user's subsequent icon correction overrides the v6 status-item mock: show a
single monochrome macOS template pie with no text. Fill represents quota remaining
(full at 100% available, empty when capped). Percentage and reset text stay in the
menu; thresholds do not tint the status icon.

| Surface | v6 requirements |
| --- | --- |
| Main menu | 344-point content width, provider headings, 24-point account rows, no title or column headings |
| Status item | One template pie icon, filled by remaining quota; no percentage/countdown text |
| Account rows | Active dot, account/group name, stacked 5-hour and weekly meters, tightest reset countdown, reset-credit count, submenu |
| Account detail | Native submenu, scoped usage, exact local reset plus countdown, freshness, read-only reset credits, named destination actions |
| Settings | 560-point native window with General, Accounts, and Providers toolbar tabs; grouped forms |
| General | Remaining usage by default, absolute + relative reset times, 25%/10% remaining thresholds, refresh interval, login, privacy |
| Accounts | Named Codex accounts, active marker, rename, add sheet, remove inactive accounts; other provider switching remains later work |
| Switching | Progress and failure presentations, no forced termination of a busy Codex app, identity verification and rollback before success |
| Materials | System glass on floating menus/panels; ordinary grouped forms in Settings; no glass layered on glass |

Screen 6a retains older example rows with two Claude accounts, while 6d explicitly
limits switching to Codex. Treat those extra menu rows as layout examples;
Codex is the first supported switching workflow. Antigravity model groups remain
part of the Google subscription, separate from Anthropic and OpenAI accounts.

The first implementation slice covers the native menu, detail views, persistent
display preferences, account-management presentation, and an isolated design
preview. Live usage fetching and real credential-switch execution follow behind
the provider boundary. Preview data must never appear as verified live usage.

## Application identities

- Production: `com.rawcontext.rations`
- Development: `com.rawcontext.rations.dev`
- Apple signing team: Raw Context LLC, `U65DCW9TAK` (verified locally).
