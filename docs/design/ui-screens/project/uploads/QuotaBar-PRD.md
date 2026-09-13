# QuotaBar

**Product Requirements Document**  
Working title · Draft v0.1 · 12 September 2026  
Author: Chris Cheney

A lean macOS menu bar app for subscription usage, reset availability, and next reset time across frontier AI labs.

| | |
|---|---|
| Status | Draft · v0.1 |
| Platform | macOS 14+ · native menu bar · no Dock icon |
| Working title | QuotaBar (also considered: ResetBar, Headroom, Allot, Fuse) |
| Reference | Inspired by [steipete/CodexBar](https://github.com/steipete/CodexBar) — deliberately not a clone |

---

## 1. One-sentence brief

Show, in the macOS menu bar, how much of each frontier-lab subscription window is used, whether a reset is available, and the exact local date and time of the next reset — and nothing else.

## 2. Problem

Frontier labs (OpenAI, Anthropic, xAI, Google/Gemini, and others) sell subscription windows, not just tokens. Those windows reset on schedules the dashboards hide behind three clicks and a login. Hitting a cap mid-session is the actual failure mode.

Peter Steinberger’s CodexBar already solves the visibility problem. It also accumulates everything around it: 50+ providers, spend charts, cookie scraping, widgets, a CLI, Linux, incident badges, pace flames, merge-icon modes, cost scans. The useful surface is usage + reset. The rest is weight.

This product exists because the category is correct and the incumbent is the wrong shape. We are not building a better CodexBar. We are building the 10% of CodexBar that is worth opening every hour.

## 3. Goals and non-goals

### 3.1 Goals

- Glanceable usage for every enabled lab without leaving the menu bar.
- Truthful reset information: next reset as local date + time, plus a relative countdown.
- Clear answer to “is a reset available / has this window already rolled?”
- First-class support for multiple shops from day one — the name and data model must not imply OpenAI.
- Reuse credentials the user already has. No new accounts. No passwords stored by us.
- Stay small enough that a single engineer can keep it correct.

### 3.2 Non-goals (v1)

- Spend, dollar burn, invoices, Admin API cost dashboards.
- Token-level charts, history graphs, SQLite cost ledgers.
- Account switching, profile pools, proxy gateways, session routing.
- Agent activity / “is Codex running” pets, hooks, or desktop characters.
- Widgets, Touch Bar, Linux, Windows, iOS, Watch.
- Scraping every new coding IDE that ships next month.
- Notifications theater, celebrations, pace-flame metaphors.
- A CLI, a plugin marketplace, or a status-page overlay.

If a feature does not change the answer to “how much have I used, and when does it come back?”, it does not ship in v1.

## 4. Product principles

1. Clarity over coverage. Four correct labs beat forty flaky ones.
2. The menu bar is the product. The popover is a detail view, not a second app.
3. Reset time is a first-class field, not a tooltip.
4. Stale is worse than empty. Dim or mark data that we cannot stand behind.
5. No new identity system. We read existing sessions; we do not become a password manager.
6. Provider adapters are plugins in the architecture, not features in the UI.

## 5. Users and jobs

### 5.1 Primary user

A developer who pays for two or more frontier subscriptions (typical mix: ChatGPT/Codex + Claude + Grok and/or Gemini) and hits rolling windows during real work. They already have CLIs or desktop apps signed in on the same Mac.

### 5.2 Jobs to be done

| Job | Trigger | Success |
|---|---|---|
| Check remaining | About to start a long agent run | Knows whether the window will survive the run |
| Wait for reset | Just hit a cap | Sees the exact local reset time; stops polling the website |
| Pick a shop | Two labs available, one is dry | Switches work to the lab that still has headroom |
| Confirm refill | Morning, or after a meeting | Sees that a window has already reset without opening a dashboard |

## 6. Scope

### 6.1 In

- Native macOS menu bar extra (`LSUIElement` / `MenuBarExtra`). No Dock icon.
- One compact status item by default. Optional per-provider items is v1.1, not a blocker.
- Per-provider, per-window usage: used %, remaining %, raw used/limit when the source gives numbers.
- Per-window reset: absolute local timestamp and relative countdown.
- Reset availability: whether the current window can still reset / has remaining resets / has already rolled, when the provider exposes that.
- Manual refresh + quiet automatic refresh.
- Enable/disable providers. Store only local preferences + Keychain secrets we did not invent.
- Launch at login toggle.

### 6.2 Out

- Everything in §3.2.
- Editing provider plans, buying more quota, or opening billing portals beyond a single “Open dashboard” link per provider.
- Multi-account rotation. One active identity per provider in v1. Additional accounts are a later adapter concern, not UI.

## 7. Information architecture

### 7.1 Objects

| Object | Meaning |
|---|---|
| Lab / Provider | A shop: OpenAI, Anthropic, xAI, Google, etc. Not a model name. |
| Account | The signed-in identity we discovered. Display email/plan only if already available locally. |
| Window | A quota bucket with a period: session (e.g. 5h), daily, weekly, monthly. A provider may have several. |
| Snapshot | One fetch of windows for one provider at one time. Has `fetchedAt` and a freshness state. |

### 7.2 Window fields (canonical)

Every adapter must normalize into this shape. Missing fields are allowed; invented fields are not.

| Field | Required | Notes |
|---|---|---|
| `id` | yes | Stable within provider, e.g. `session` \| `weekly` |
| `label` | yes | Human: “5-hour”, “Weekly”, “Monthly” |
| `usedPercent` | if known | 0–100. Prefer provider-reported % over computed. |
| `remainingPercent` | if known | Derived if only used% exists. |
| `used` / `limit` | if known | Absolute units only when the source is honest. Do not fake token counts. |
| `resetsAt` | if known | UTC instant. Render in local tz as date + time. |
| `resetsIn` | derived | From `resetsAt` vs now. Never stored as source of truth. |
| `resetAvailable` | if known | Boolean or count. Leftover reset credits, or “window already rolled.” |
| `unit` | if known | `percent` \| `requests` \| `tokens` \| `credits` — display only. |
| `state` | yes | `ok` \| `capped` \| `unknown` \| `stale` \| `error` |

## 8. Functional requirements

### 8.1 Menu bar

- **FR-1** The app lives only in the menu bar. No Dock tile, no floating window on launch.
- **FR-2** Default status item shows the tightest (most consumed or nearest-to-cap) enabled window across enabled providers, as a short percent plus a tiny meter.
- **FR-3** Status item color is semantic: comfortable / warning / critical / stale / error. Defaults: warning ≥ 75%, critical ≥ 90%. Thresholds are settings.
- **FR-4** Click opens a popover. Right-click (or an overflow control) exposes Refresh, Settings, Quit.
- **FR-5** If data is stale past the freshness budget, the item dims and the popover says so. Do not display a confident percent we no longer believe.

### 8.2 Popover

- **FR-6** Popover lists enabled providers. Each provider block shows plan name if known, freshness (“Updated 2m ago”), and its windows.
- **FR-7** Each window row shows: label, used%, remaining% or remaining units, a progress bar, next reset as local date and time, and relative countdown.
- **FR-8** If the provider exposes reset availability (credits remaining, extra resets, already-reset flag), show it on the same row. Do not invent a “resets left” number.
- **FR-9** Capped windows are visually first. Sort windows inside a provider by pressure, then by soonest reset.
- **FR-10** A Refresh action re-fetches the visible providers immediately and shows in-flight state.
- **FR-11** An “Open dashboard” action per provider opens the vendor’s official usage page in the default browser. One link. No embedded webviews in v1.

### 8.3 Settings

- **FR-12** Settings is a small native window: providers on/off, warning/critical thresholds, refresh interval, launch at login, display as used vs remaining, reset as absolute / relative / both (default both).
- **FR-13** Provider setup is “detect what is already signed in, then confirm.” If nothing is found, show a short “install CLI / sign in once” hint — not a tutorial product.

### 8.4 Refresh and freshness

- **FR-14** Auto-refresh on a conservative interval (default 5 minutes; range 2–15). Refresh also when the popover opens if the snapshot is older than 60 seconds.
- **FR-15** Never hammer vendor APIs. Per-provider minimum spacing is adapter-defined and must be respected even on manual refresh spam (manual refresh may bypass once, then cooldown).
- **FR-16** A snapshot older than 20 minutes is stale. A failed fetch keeps the last good snapshot, marked stale/error, rather than wiping the UI to zero.

### 8.5 Time

- **FR-17** All stored timestamps are UTC. All displayed timestamps are the user’s current timezone, including date (e.g. Sun 13 Sep, 4:00 AM).
- **FR-18** Countdown format: under 1 hour as `Xm` or `Xh Ym`; over 1 hour as `Xh Ym`; over 24 hours as `Xd Yh`. Never show only a raw ISO string.
- **FR-19** When `resetsAt` is unknown, say “Reset time unknown.” Do not guess from the window label.

## 9. Provider requirements

### 9.1 v1 labs

v1 is successful if these four are correct. Everything else waits.

| Lab | Preferred source | What we must show |
|---|---|---|
| OpenAI | Existing Codex / ChatGPT local session (CLI auth or local app-server) | Subscription windows (typically 5-hour + weekly), used%, next reset, any remaining reset credits if exposed |
| Anthropic | Existing Claude Code / Claude CLI OAuth in Keychain or local credentials file | Session + weekly (and model-scoped if the API already returns it). Reset times. No cookie-scraping circus in v1 if OAuth works. |
| xAI | Existing Grok CLI / local login | Plan usage, included-credit window if that is what the sub uses, reset timing |
| Google | Existing Gemini CLI auth | Whatever quota windows the signed-in plan actually has. Do not pretend Gemini has Codex’s 5h/weekly shape if it does not. |

Adapter contract: each lab is a module that produces

```ts
Snapshot {
  provider: string
  account?: Account
  windows: Window[]
  fetchedAt: Instant
  error?: string
}
```

The UI never speaks a vendor’s private JSON.

### 9.2 Auth policy

- Reuse local artifacts only: CLI auth files, Keychain items the vendor already wrote, official device/OAuth flows the user completes in the vendor’s tool.
- Do not store passwords. Do not become a cookie jar in v1.
- If an adapter needs a token we must hold, it lives in Keychain with a clear service name.
- No cloud backend. No telemetry beyond an optional off-by-default Sparkle update check later.

### 9.3 Later labs

Cursor, Copilot, OpenRouter, and others are explicitly backlog. Adding a lab is an adapter + a toggle, not a product expansion — unless that lab forces a new concept (prepaid balance, seat pool). Prepaid dollar balance is out of v1 even if easy.

## 10. UX specification

### 10.1 Status item (default)

Single item. Example states:

| State | Menu bar |
|---|---|
| Healthy | `▮▮▯  41%` |
| Warning | `▮▮▮  78%` (warning color) |
| Critical / capped | `▮▮▮  100%  ·  2h 14m` |
| Stale | Dimmed last % · stale mark |
| No providers | Neutral icon only |

When a window is capped, prefer showing countdown to reset on the bar itself. That is the only extra token allowed on the item.

### 10.2 Popover layout

- Header: app name, last global refresh, Refresh button.
- Provider sections, enabled only.
- Window rows as specified in §8.2.
- Footer: Settings…, Quit.

Popover is allowed to be tall. It is not allowed to grow sideways into a dashboard. No tabs. No charts.

### 10.3 Empty and error

- Zero providers enabled → one paragraph and a button to Settings.
- Provider signed out → that section says so and offers “Open sign-in docs” / dashboard link. Other providers still render.
- Partial failure is normal. Never blank the whole popover because Gemini failed.

## 11. Non-functional requirements

- **NFR-1** Native Swift / SwiftUI. No Electron, no webview shell.
- **NFR-2** Idle CPU and energy must be boring. No tight loops, no accessibility/screen-recording permissions.
- **NFR-3** Memory stays small. No unbounded history store.
- **NFR-4** Works offline enough to show the last snapshot as stale.
- **NFR-5** Signing + notarization for distribution. Homebrew cask is nice-to-have, not MVP.
- **NFR-6** Code and UX copy stay short. No onboarding carousel.
- **NFR-7** Adapter failures are isolated. A bad OpenAI parse cannot crash Anthropic.

## 12. Privacy and trust

- All data stays on device.
- We do not crawl the disk. Adapters read known paths only.
- We do not log tokens, cookies, or emails to disk in plaintext logs.
- “Hide personal information” is a single toggle that redacts emails in the popover.
- README states exactly which files/Keychain items each adapter touches.

## 13. What we are not copying from CodexBar

CodexBar is the existence proof and the anti-spec. Treat this table as a fence.

| CodexBar | This app |
|---|---|
| 50+ providers | 4 labs in v1, adapter-shaped for more |
| Spend, cost scans, charts | None |
| CLI + Linux + widgets | macOS menu bar only |
| Cookie import / browser sessions | Official local auth only in v1 |
| Pace flames, celebrations, incident badges | Percent, bar, reset clock |
| Merge-icons + layout token editor | One status item, one popover |
| Name implies OpenAI Codex | Name must survive adding Grok and Gemini |

## 14. Success criteria

### 14.1 MVP is done when

- A signed-in OpenAI subscription window and its next reset render correctly.
- A signed-in Anthropic subscription window and its next reset render correctly.
- At least one of xAI or Gemini does the same.
- Capped state shows a local reset timestamp a human can trust without opening a browser.
- The app can sit in the menu bar all day without becoming a science project in Activity Monitor.
- A new lab can be added by writing one adapter and a toggle — no UI rewrite.

### 14.2 Product-quality bar

- Wrong reset time is a P0. A missing pretty animation is not a bug.
- If two sources disagree, show the official usage API / CLI-reported window, not a reconstructed guess from log files, unless that is the only source and it is labeled “estimated.”

## 15. Milestones

| Cut | Name | Ships |
|---|---|---|
| M0 | Skeleton | Menu bar extra, popover chrome, settings shell, fake snapshot fixture |
| M1 | OpenAI truth | Live OpenAI/Codex windows + reset clock from local auth |
| M2 | Second lab | Anthropic live. Proves the adapter boundary is real. |
| M3 | Frontier set | xAI and/or Gemini. Freshness, stale, errors, launch-at-login |
| M4 | Ship | Notarized build, README with exact auth paths, name locked |

## 16. Naming

Shipping name is still open. Constraints: must not say Codex; must not collapse to one lab; should work as a menu-bar word and a GitHub slug.

| Candidate | Note |
|---|---|
| QuotaBar | Clearest. Working title of this PRD. |
| ResetBar | Leans into the clock, which is the actual job. |
| Headroom | Ownable. Less “yet another Bar.” |
| Allot | Short product word. Good slug. |
| Fuse | Burns down to reset. Sharper, slightly cute. |

Avoid: CodexBar, ClaudeBar, AgentBar, AIUsageBar, AIQuotaBar — already in market.

## 17. Open questions

| # | Question | Default if unanswered |
|---|---|---|
| Q1 | One menu item vs one item per lab? | One item. Per-lab items only if users demand them. |
| Q2 | Do we ever show estimated usage from local session logs? | Only labeled “estimated,” and never in preference to an official usage endpoint. |
| Q3 | Multiple accounts per lab in v1? | No. Show the active local identity only. |
| Q4 | Threshold notifications? | Out of v1. The bar changing color is the notification. |
| Q5 | Is “resets available” a count, a boolean, or vendor-specific copy? | Vendor-specific copy mapped onto `resetAvailable` + optional count. |
| Q6 | License and public repo? | MIT, public, after M1 is not embarrassing. |

## 18. Acceptance checklist

A build is not v1 unless all of the following are true:

- I can read usage for at least two labs without opening a browser.
- I can see the next reset as a calendar date and a clock in local time.
- When a window is exhausted, the UI tells me when it comes back, not just that it is at 100%.
- If a reset credit / extra reset exists on the plan and the vendor exposes it, it is visible.
- A third lab can be added without renaming the app or redesigning the popover.
- There is no spend chart, no activity pet, and no provider grid to apologize for.

---

Next document after name lock: adapter notes per lab (exact files, endpoints, and field maps). That is an engineering spec, not this PRD.
