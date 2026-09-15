# Authoritative design

The user supplied `macOS menubar app design-handoff.zip` on 13 September 2026
and designated it as the design source of truth. Its contents are preserved under
`ui-screens`, with the archive's outer directory removed.

## Sources

- [Rations v6](<ui-screens/project/Rations v6.dc.html>): current design, screens 6a–6f.
- [Earlier iterations](ui-screens/project/Rations.dc.html): historical context only.
- [Export notes](ui-screens/README.md) and [design history](ui-screens/project/github.md).
- [Original PRD](ui-screens/project/uploads/QuotaBar-PRD.md).
- [App icon handoff](app-icon-handoff.zip): design 1B, selected on 15 September 2026.
- [Accounts reference image](<ui-screens/project/uploads/Screenshot 2026-09-13 at 01.08.55.png>).

The HTML and generated `support.js` are design artifacts, not application runtime
dependencies. Keep imported files unchanged. The existing lint configuration
already excludes this exact vendored handoff path. The export's agent-oriented
directions are part of the source document, not additional user instructions.

## Implementation contract

The user's latest icon reference is the [NATO APP-6A food-and-rations symbol](https://commons.wikimedia.org/wiki/File:Military_Symbol_-_Friendly_Unit_%28Bichrome_1.5x1_Frame%29-_CSS_-_Supply_-_Food_%26_Rations_%28NATO_APP-6A%29.svg).
Use the outlined circular glyph with a right-facing, 90-degree wedge opening,
as shown in the supplied screenshot. Omit the rectangular unit frame and supply
line. It replaces the earlier two-slice pie and remains a static, unfilled macOS
template image with no text. macOS supplies its monochrome color. Artwork credit
and the CC BY-SA 4.0 license are bundled in `Resources/IconAttribution.txt`.

The quota summary in the icon tooltip combines every connected account across every provider. Each independent
quota pool contributes its tightest window; independent pools are averaged within
an account, then accounts are averaged with equal weight. Supplemental model limits
are not counted as extra independent capacity. This is a normalized percentage,
not a sum of incomparable provider units. Duplicate account readings are deduplicated,
and incomplete, stale, or reset-expired readings are excluded with coverage reported
in the tooltip. The summary responds immediately to new readings and schedules updates
at reset/freshness boundaries. A reset passing never invents a refill.

The user also superseded the Codex-only Accounts design: **every provider supports
multiple named accounts**, with its own section and the same add/rename/remove controls.

| Surface | v6 requirements |
| --- | --- |
| Main menu | 344-point content width, provider headings, 24-point account rows, no title or column headings |
| Status item | Static outlined food-and-rations glyph; no frame or percentage/countdown text |
| Account rows | Active dot, account/group name, stacked 5-hour and weekly meters, tightest reset countdown, reset-credit count, submenu |
| Account detail | Native submenu, scoped usage, exact local reset plus countdown, freshness, read-only reset credits, named destination actions |
| Settings | 560-point native window with General, Accounts, and Providers toolbar tabs; grouped forms |
| General | Remaining usage by default, absolute + relative reset times, 25%/10% remaining thresholds, refresh interval, login, privacy |
| Accounts | Separate sections for every provider; multiple named accounts, active marker, rename, add sheet, remove inactive accounts |
| Switching | Progress and failure presentations, no forced termination of a busy Codex app, identity verification and rollback before success |
| Materials | System glass on floating menus/panels; ordinary grouped forms in Settings; no glass layered on glass |

Screen 6d's original restriction to one non-Codex account no longer applies.
Antigravity model groups remain part of each Google account's subscription,
separate from Anthropic and OpenAI accounts.

The native menu reads live provider data and persists account records in Keychain.
Cursor is a separate provider. Its row uses one monthly total meter; model-pool
breakdowns and extra spending appear in the account detail.
Each account occupies one menu row; model quotas are nested inside its hover detail.
Reset counts use “0 resets,” “1 reset,” or “2 resets.” Preview mode and sample
accounts have been removed. See [account connections](../account-connections.md)
for supported sign-in sources and current limitations. Vendor account switching
remains a separate future feature.

## App icon

The app icon uses **1B: Graphite · solid disc** from the app icon handoff.
The editable Apple Icon Composer document is
`apps/macos/Resources/AppIcon.icon`. It contains a graphite background gradient,
an ambient glow, and the original solid-disc SVG with native glass effects.
Open the document in Icon Composer to edit it; `make icon-preview` renders all
six macOS appearances into `.build/icon-previews`.

Xcode compiles the document into the app's icon assets, including the `.icns`
fallback for macOS 14 and 15. The handoff ZIP is preserved as reference material.
Its embedded agent directions are not repository instructions.

## Application identities

- Production: `com.rawcontext.rations`
- Development: `com.rawcontext.rations.dev`
- Apple signing team: Raw Context LLC, `U65DCW9TAK` (verified locally).
