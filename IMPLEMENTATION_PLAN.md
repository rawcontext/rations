# Rations implementation plan

Date: 13 September 2026

Repository: `ccheney/rations`

Status: Native v6 UI in progress; live provider implementation remains planned

The [authoritative v6 handoff and subsequent user corrections](docs/design/README.md) govern interface details. All providers support multiple named accounts, the icon aggregates their remaining quota, the menu uses compact provider sections, and Settings has General/Accounts/Providers tabs. Live saved-account authentication and switching remain separate from this first UI slice.

## 1. Outcome and scope

Build a small native macOS menu bar app that answers two questions: **how much subscription quota is used, and exactly when does it reset?** Reuse the relevant data-access implementations from existing open-source monitors, then build a focused interface and stricter handling of incomplete data around them.

Product input is `QuotaBar-PRD.md`, draft v0.1, dated 12 September 2026. This plan incorporates the subsequent user decisions: investigate and reuse public implementations, use **Google Antigravity subscriptions instead of Gemini CLI**, and scaffold a **Bazel monorepo**. The product name is **Rations**, matching the `rations` repository.

The four v1 integrations are:

| Provider | Subscription surface | Display name |
|---|---|---|
| OpenAI | Codex usage associated with the active ChatGPT subscription | Codex |
| Anthropic | Active Claude subscription and its applicable quota windows | Claude |
| Google | Antigravity subscription, including its separate shared model groups | Antigravity |
| xAI | Grok / SuperGrok included subscription usage | Grok |

These sources expose particular product entitlements. A Codex window is not every ChatGPT limit, and Antigravity's Claude-model pool is not the user's Anthropic subscription. Preserve those distinctions in labels and identifiers.

Ship one menu bar item, a narrow native menu, native settings, provider detection, manual and automatic refresh, accurate local reset dates, reset-credit visibility where available, offline snapshots, and launch at login. Support multiple named accounts for every provider, tracking the active local identity independently per provider. Additional providers remain adapter work after v1; Gemini CLI is not part of this implementation.

Exclude spend charts, session-log estimates, automatic account rotation, browser-cookie extraction, custom OAuth sign-in screens, reset-credit redemption, notifications, widgets, a public CLI, plugins, and a backend. Manual Codex switching is included by the v6 design. Reusing an installed vendor CLI internally is compatible with having no Rations CLI product.

**Release cuts:** resolve the PRD's different provider-count checklists explicitly. An internal preview can ship with Codex + Claude. MVP requires those two plus Antigravity or Grok. The intended v1 includes all four; an unavailable adapter must be reported as unfinished rather than counted as working support.

## 2. What to reuse

Research checked public source on 13 September 2026. These are implementation references, not proof that the user's particular accounts have already been tested. No live credentials were read for this plan.

| Project and reviewed revision | Findings and reuse decision |
|---|---|
| [CodexBar](https://github.com/steipete/CodexBar/tree/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8), `afa483f2a287e` | Primary donor for provider parsers, local credential discovery, Antigravity process handling, and Grok requests. Its [MIT license](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/LICENSE) supports reuse with attribution. |
| [UsageBar](https://github.com/methol-dev/usage-bar/tree/2a5ff2c7d0cc72feda4e732ef2e9b3d5df0bfee0), `2a5ff2c7d0cc` | Smaller examples of Codex HTTP fetching, Claude Keychain/file access, and refresh coordination. Reuse focused pieces under its [BSD-2-Clause license](https://github.com/methol-dev/usage-bar/blob/2a5ff2c7d0cc72feda4e732ef2e9b3d5df0bfee0/LICENSE). |
| [ClaudeBar](https://github.com/tddworks/ClaudeBar/tree/b4077683c95b2863d65da6d8b8bd6788a5a77736), `b4077683c95b2` | Cross-check of Claude OAuth and Antigravity quota-summary behavior. The inspected repository tree did not expose a license file, so use it as behavioral research; select the licensed implementations above for copied code. |

At each port, record the upstream revision, original file, destination, and modifications in `docs/upstream-reuse.md`; carry the applicable notices into `THIRD_PARTY_NOTICES.md` and the distributed bundle. Copy small coherent implementations and their useful regression cases. Adapt them to our models without importing the donor application's UI, history systems, or provider framework wholesale.

The first implementation milestone is a short port-and-verify exercise, not an open-ended search for a new API. Review the pinned code against current upstream before copying, and retain tests around the behavior we adopt.

## 3. Provider implementation recipes

### 3.1 Codex

**Primary path:** port the read-only OAuth usage request from [CodexBar's fetcher](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Codex/CodexOAuth/CodexOAuthUsageFetcher.swift). [UsageBar's compact client](https://github.com/methol-dev/usage-bar/blob/2a5ff2c7d0cc72feda4e732ef2e9b3d5df0bfee0/macos/Sources/UsageBar/Providers/Codex/CodexUsageClient.swift) confirms the same request structure: `GET https://chatgpt.com/backend-api/wham/usage`, bearer authentication, and `ChatGPT-Account-Id` when available.

- Discover the active Codex installation and its configured credential storage. The file candidate is `$CODEX_HOME/auth.json`, defaulting to `~/.codex/auth.json`; preserve explicit profile paths. Handle Keychain-backed storage through the vendor CLI when direct file credentials are unavailable.
- Decode the primary, secondary, and additional rate-limit buckets. Map provider percentages and reset instants directly; retain bucket IDs and model scope. Use returned durations rather than assuming every primary window lasts five hours.
- Fetch reset-credit inventory separately, following the donor's `/wham/rate-limit-reset-credits` request. A failure here must not discard successfully fetched usage. Reset credits and purchased usage credits are different concepts.
- On expired credentials, prefer vendor-owned recovery. Do not overwrite Codex's shared auth file or independently race its refresh token. Re-read after recovery, then retry once if credentials changed.

**Fallback:** use a bounded `codex app-server` stdio session for Keychain-backed credentials, token recovery, or direct-endpoint incompatibility. Perform `initialize` / `initialized`, then `account/read` and `account/rateLimits/read`; no conversation is needed. Prefer `rateLimitsByLimitId` over the legacy single-bucket view and read `rateLimitResetCredits.availableCount` when present. This path and the seconds-based `resetsAt` field are documented in the [Codex app-server reference](https://developers.openai.com/codex/app-server#authentication-modes). Pin tested CLI versions and generate their protocol schema during development; treat absent newer fields as unknown.

**Proof:** compare percentages and reset timestamps with the active Codex account; test multiple buckets, missing weekly data, API-key-only auth, Keychain auth, reset-credit inventory failure, and identity changes during a request.

### 3.2 Claude

**Primary path:** port the usage-only parts of [CodexBar's Claude OAuth fetcher](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Claude/ClaudeOAuth/ClaudeOAuthUsageFetcher.swift) and compare credential loading with [UsageBar's implementation](https://github.com/methol-dev/usage-bar/blob/2a5ff2c7d0cc72feda4e732ef2e9b3d5df0bfee0/macos/Sources/UsageBar/Providers/Claude/ClaudeCLICredentialsStrategy.swift).

- Read the active vendor credential location: the `Claude Code-credentials` Keychain item or `.credentials.json` under the active Claude configuration directory. Distinguish `claudeAiOauth` from unrelated MCP OAuth credentials. Verify custom-directory Keychain naming against the installed CLI.
- Request `GET https://api.anthropic.com/api/oauth/usage` with bearer auth and the donor's `anthropic-beta: oauth-2025-04-20` header. Confirm the credential has the usage endpoint's required `user:profile` scope.
- Map `five_hour`, `seven_day`, and returned model-scoped weekly buckets, including the newer `limits[].weekly_scoped` shape. Parse `utilization` and `resets_at`; ignore monetary `extra_usage` fields.
- Keep credentials in memory for requests. On authentication failure, re-read the vendor-owned storage once and retry only with a changed credential; otherwise provide a short vendor sign-in hint. Background refresh must not repeatedly trigger Keychain dialogs.
- Handle HTTP 429 and `Retry-After` centrally. Do not fall through to a second endpoint merely to circumvent throttling.

This is an undocumented endpoint used by existing monitors. Anthropic's current [credential guidance](https://code.claude.com/docs/en/legal-and-compliance#authentication-and-credential-use) is restrictive about third-party handling of Claude session tokens; public monitor code does not establish an officially supported integration contract. Track that dependency alongside schema and credential-storage compatibility, while keeping this implementation to existing local sign-in and read-only usage retrieval.

**Fallback research:** CodexBar also parses the unmodified CLI's `/usage` output. Adopt that only if it supplies trustworthy timestamps without starting inference. Claude's documented [status-line quota fields](https://code.claude.com/docs/en/statusline#rate-limit-usage) are useful corroboration, but appear after an API response and do not provide independent five-minute polling. Installing a status-line hook is not part of this plan.

**Proof:** real session and weekly readings, no model bucket duplication, missing scope, MCP-only Keychain payload, denied Keychain access, expired credentials, long throttling cooldown, and partial/malformed response fields.

### 3.3 Antigravity

**Primary path:** port CodexBar's local Antigravity transport and quota-summary parser. Relevant sources are [process/endpoint discovery](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Antigravity/AntigravityStatusProbe.swift), [the managed `agy` session](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Antigravity/AntigravityCLISession.swift), and [the quota-summary parser](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Antigravity/AntigravityQuotaSummaryParser.swift).

- Reuse an authenticated Antigravity app service when available; otherwise reuse or briefly start the installed, signed-in `agy` CLI. Discover only endpoints belonging to the verified vendor process. Do not require screen recording, accessibility access, or visual scraping.
- Request `/exa.language_server_pb.LanguageServerService/RetrieveUserQuotaSummary` over the local service. Preserve the source-specific CSRF behavior and connection requirements. Any local certificate exception must be limited to that verified loopback service, never the shared remote HTTP client.
- Decode the supported `response`, `summary`, or root envelopes. Preserve `groups`, `bucketId`, `displayName`, `remainingFraction` (including nested `remaining`), `resetTime`, and `disabled`.
- Keep the returned shared groups separate. Current observed buckets include `gemini-5h`, `gemini-weekly`, `3p-5h`, and `3p-weekly`; display returned group labels and do not hard-code the model catalog. Compute used percentage as `(1 - remainingFraction) * 100` only when the fraction is valid.
- A Claude/GPT group in this response belongs to **Antigravity**. Never merge it with Claude or Codex subscriptions. Do not add individual models together when they share a pool.
- Prefer a complete quota summary over older per-model responses. A missing window, disabled bucket, or model-availability response does not mean unused quota. Preserve reset time even if usage is unknown.
- Bound cold-start readiness, subprocess output, and total fetch time. Keep at most one owned helper, stop it after a measured idle grace period, and never terminate an Antigravity process started by the user.

CodexBar's [adapter notes](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/docs/antigravity.md) describe richer local app/CLI quota summaries and less complete remote responses. [ClaudeBar independently queries a remote quota-summary endpoint](https://github.com/tddworks/ClaudeBar/blob/b4077683c95b2863d65da6d8b8bd6788a5a77736/Sources/Infrastructure/Antigravity/AntigravityCloudCodeClient.swift). Keep remote OAuth access as a bounded fallback candidate only if a real-account check proves equivalent quota data; it is not needed for the first local-source implementation.

**Proof:** compare both shared groups with Antigravity's quota display; test app open/closed, signed-in `agy` only, cold startup, missing summary, disabled buckets, unknown reset, and helper cleanup. An open-desktop-only demo does not satisfy the CLI fallback acceptance test.

### 3.4 Grok

**Primary path:** port the credential loading and subscription-percentage path from CodexBar's [Grok adapter](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Grok/GrokStatusProbe.swift) and [credits-proxy fetcher](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers/Grok/GrokCreditsProxyFetcher.swift).

- Reuse the active official Grok CLI login from `~/.grok/auth.json`, respecting the installed version's supported home override. Capture identity and token together once per fetch; let Grok own token refresh.
- Request `GET https://cli-chat-proxy.grok.com/v1/billing?format=credits` with bearer auth and `x-xai-token-auth: xai-grok-cli`.
- Map `config.creditUsagePercent`; reset comes from `config.currentPeriod.end`, with `billingPeriodEnd` accepted only after confirming it is the included quota's boundary for that response shape. Optional `/v1/settings` enrichment supplies a plan label within a separate small deadline.
- Deliberately omit the donor's `onDemandUsed / onDemandCap` fallback: that ratio measures a spending cap and cannot establish included subscription utilization. If only a reset period is returned, show it alongside unknown usage.
- Grok's [official usage documentation](https://docs.x.ai/grok/faq#usage--limits) describes a shared weekly allowance and a displayed reset schedule. Confirm the response matches the signed-in plan; do not infer a weekly/monthly window from the distance to its end date.

**Fallback:** probe `grok agent stdio` / `x.ai/billing` only on versions where it is supported. CodexBar's [Grok notes](https://github.com/steipete/CodexBar/blob/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/docs/grok.md) report `Method not found` on version 0.1.210. Its bearer gRPC fallback is a candidate only if the credits proxy lacks data on a target plan; port no cookie-import branch and accept no guessed percentage.

**Proof:** compare included percentage and reset with Grok's Usage page; test omitted percentage, on-demand-only fields, expired auth, unsupported team accounts, billing-only dates, and unavailable ACP methods.

## 4. Native architecture

Use Swift and SwiftUI targeting macOS 14+, with Foundation networking, Security for credential access, and ServiceManagement for launch at login. Bazel owns the app, core, and provider targets and generates the Xcode project. The scaffold pins Bazel 9.2.0 and the tested Apple/Swift rules, and selects Xcode 27 beta as requested. Prefer system frameworks and existing vendor installations over bundled third-party runtimes.

Use [`MenuBarExtra`](https://developer.apple.com/documentation/swiftui/menubarextra) with window-style content and `LSUIElement = true`. Implement Refresh, Settings, and Quit in the popover footer, satisfying the PRD's overflow alternative without a custom right-click system. Validate status-label coloring and popover lifecycle in M0; use a narrow `NSStatusItem` / `NSPopover` bridge only if native SwiftUI cannot meet those requirements on macOS 14.

```text
apps/macos/                    SwiftUI app, popover, settings, bundle resources
packages/core/                 Normalized models and domain behavior
packages/providers/            Provider contract and future vendor adapters
tools/cognitive-complexity/     Shared Swift lint tool and regression tests
tools/testing/                 Bazel test runtime support
docs/                          Adapter notes, reuse record, release checklist
scripts/                       Bootstrap and normal checks
script/                        Native build/run/debug entry point
```

Keep provider adapters as folders in the `packages/providers` Bazel package initially. The dependency direction is UI → application state → provider protocol → transport; the domain depends on none of the UI or vendor response types. An `@MainActor` observable store publishes immutable view data. A refresh actor owns per-provider work and deadlines; file, Keychain, and process operations do not block rendering.

The adapter contract supplies provider metadata, detection results, capabilities, a minimum refresh spacing, and an async snapshot fetch. Each adapter owns its credential reader, wire DTOs, normalization, and source preference. Shared services cover HTTP, process lifetime, clock, and cache—not a general-purpose plugin system. A provider failure becomes a typed result rather than escaping and cancelling sibling providers.

## 5. Data and correctness rules

Refine the PRD's canonical shape so usage, connectivity, and reset availability cannot overwrite one another:

| Type | Required information |
|---|---|
| `ProviderSnapshot` | Provider/product ID, opaque account scope, windows, source identifier, observation time, local fetch completion time, optional plan and reset-credit inventory |
| `QuotaWindow` | Stable source bucket ID, label, optional group/model scope and duration, optional percentage/raw quantities/unit, optional reset instant, quota condition |
| `ResetAvailability` | Separately optional credit count, provider-reported eligibility, and confirmed rollover evidence; attach at account or bucket scope as the source specifies |
| `ProviderRuntime` | Last good snapshot, latest attempt, in-flight state, typed error, next eligible refresh, account generation, derived freshness |
| `ProviderCapabilities` | Supported usage/reset fields, source detail level, dashboard URL, setup hint, hard minimum request spacing |

Persist source instants, never countdown strings. Keep provider wire dates and percentages out of SwiftUI. In the UI, derive `ok`, `capped`, `unknown`, `stale`, and `error` presentation from the independent quota and fetch states; a cached capped window can also be stale.

- **Unknown is not zero:** nulls, missing fields, invalid percentages, zero denominators, and non-finite values stay unknown. Raw finite `used / limit` can provide a ratio only for the same quota and units. Bound meter drawing to 0–100 without silently turning malformed data into healthy readings.
- **Coverage is explicit:** keep partial valid windows and report unavailable fields. A successful empty response does not silently refresh the age of older windows. Retain per-field/source timestamps if optional credit or reset data survives a partial fetch.
- **One logical bucket:** identify windows using provider/product, account scope, and vendor bucket ID. Deduplicate only demonstrated aliases; do not sum overlapping session and weekly limits or Antigravity model pools.
- **One account at a time:** capture account scope at request start and reject late responses after identity changes or provider disablement. On identity change, remove the previous account's readings from the active display and cache. Match fallback data to that identity before merging.
- **Reset credits are inventory:** unknown, zero, and a positive count are distinct. A credit count does not prove eligibility now. Render account-scoped credits once in the provider header, or beside a row only when applicability is known. No consume/reset mutation is exposed.
- **Reset time passing is not refill evidence:** at zero, display “Reset due · checking,” retain but mark the old reading unconfirmed, and schedule an eligible refresh. Never set usage to zero or claim “Reset available” solely because the clock advanced.
- **Confirmed rollover:** accept an explicit vendor signal or a subsequent authoritative response identifying the new window. A lower percentage alone is insufficient. If no proof exists, show current usage and the new reset time without a refill claim.
- **Source disagreement:** keep percent, scope, and reset from one coherent authoritative reading. Optional enrichment must not attach another account's plan or another period's reset to it. Record a sanitized discrepancy and retry rather than averaging.

For pressure selection, rank enabled, current, comparable windows by explicit capped state, then used percentage, then earliest known reset, then stable provider/bucket ID. Unknown resets sort last. A provider-declared cap without a percentage can show a capped indicator without inventing `100%`. Sort rows within each provider by the same rules; keep provider sections in stable order.

## 6. Interface behavior

- **Menu item:** one monochrome macOS template pie with no text, aggregating remaining quota across all connected accounts and providers. Use the tightest window per independent pool, average pools within each account, then average accounts equally. Exclude duplicate, stale, incomplete, and reset-expired readings; expose coverage in the tooltip and accessibility label. React immediately to snapshot changes and at scheduled freshness/reset boundaries, without guessing a refill. Menu visibility and Left/Used settings do not change the aggregate.
- **Degraded coverage:** when another enabled provider is stale or failing, retain a current selected reading with a small degraded marker. If no current readings exist, dim the last reading and mark it stale; show a neutral/error symbol if there is no usable cache. No providers enabled produces a neutral icon.
- **Popover:** target roughly 360–400 points wide with a vertically scrollable body capped to the available screen height. Header has the title and refresh state. Each provider shows its name, optional locally known plan, freshness, applicable windows, and one official dashboard action. Failed providers stay visible without blocking other sections.
- **Window row:** label and group, used/remaining values, a meter, local reset date and time, and countdown. Unknown values get explicit text. Capped rows have textual status as well as color. Set a clear distinction between “Updated 2m ago” and “Refresh failed; last data 2m ago.”
- **Time formatting:** default to absolute + relative. Use the user's current locale, time zone, and clock convention, including a calendar date. Show `<1m` below a minute, `Xm` below an hour, `Xh Ym` below 24 hours, then `Xd Yh`. Clamp expired countdowns to “Reset due”; never render negatives. Update immediately after clock or time-zone changes and include zone context for ambiguous local times.
- **Settings:** provider toggles/detection, refresh interval, thresholds, used/remaining mode, absolute/relative/both reset mode, launch at login, and hide personal information. Validate `0 ≤ warning < critical ≤ 100`. Redact emails by default; include no personal details in the menu item.
- **Setup:** check known installation/auth locations, show what was found, then let the user enable the provider. Request interactive Keychain access only from an explicit setup/reconnect action. If unavailable, show a short vendor sign-in instruction. A GUI launch must not depend on inheriting the user's interactive shell PATH; support a chosen executable path in provider setup when known installation paths fail.
- **Accessibility:** keyboard access, VoiceOver labels including provider/window, readable light/dark/high-contrast states, no reliance on color alone, and layout tests with long plan names and localized dates. Closing Settings or the popover leaves the menu app running; Quit stops app-owned work.

## 7. Refresh, persistence, and resource use

Implement one scheduler with an independent state per enabled provider. Refresh the enabled set at launch, after enablement, on manual refresh, and on a default five-minute interval configurable from two to fifteen minutes. Popover opening requests a refresh for data older than sixty seconds. Coalesce overlapping triggers and publish each provider as soon as it finishes.

The next request must respect the maximum of the trigger's due time, adapter minimum spacing, and server cooldown. Manual refresh bypasses the ordinary schedule, never a hard minimum or `Retry-After`; show the pending/cooldown state. Start with a conservative sixty-second minimum unless the adapter requires longer. Respect both seconds and HTTP-date forms of `Retry-After`; use bounded exponential backoff with jitter for transient failures.

Use a per-provider overall deadline, initially twenty seconds including startup, fallback, and parsing; tune from the first measurements. Keep at most one in-flight fetch per provider and cap concurrent heavy CLI launches. Cancellation must stop owned subprocess work and prevent stale results from publishing. A fallback shares the original deadline and stops once adequate data is obtained.

Launch vendor helpers with explicit executable paths and arguments in a neutral app-owned working directory. Do not submit inference prompts to obtain usage or load the user's current project. Verify any version-specific options needed to suppress unrelated startup integrations during the source-port milestone.

Data becomes stale after twenty minutes without a trustworthy observation; a failed fetch immediately marks the last reading as unverified/error even within that budget. Track fetch completion separately from observation time so a cached upstream response cannot masquerade as new usage. Schedule freshness and reset-boundary transitions even while the popover is closed.

On sleep, suspend scheduled work. On wake or restored connectivity, perform one coalesced due refresh with jitter. Use monotonic time for spacing and wall-clock instants for vendor resets. Recompute display after wall-clock changes and treat future-dated/corrupt caches conservatively. Minute-level display updates are sufficient; no one-second background polling loop.

Persist one normalized last-good snapshot per active provider to an atomic, versioned file under Application Support, plus preferences in UserDefaults. Store no history, raw HTTP bodies, tokens, or emails in that file. Restore it as unverified until identity and freshness can be checked; offline startup still shows its age. Disablement stops requests and clears transient credential state. Unreadable/old cache schemas must not prevent launch.

Use ephemeral HTTP sessions without cookie storage or disk response caches. Request credentials stay in memory; any app-owned secret that proves necessary belongs in a clearly named Keychain service. Log only fixed error categories, timings, and provider IDs. Direct network usage goes to the relevant vendor; there is no Rations server or analytics service.

Initial performance targets, to be measured in release builds: cached popover opens within 150 ms; app process averages below 1% CPU when idle; app memory below roughly 100 MB after warm-up; no sustained memory growth over an eight-hour run. Measure helper CPU and memory separately and as a combined total, and verify helpers actually stop after their idle grace period. These are engineering targets, not claims about the current repository.

## 8. Implementation sequence

Estimates are engineering days for one experienced Swift developer, assuming access to the four signed-in subscriptions and a signing identity for distribution. External endpoint changes or missing account access extend the affected milestone; fixture work can continue independently.

| Milestone | Work and concrete deliverable | Dependencies | Exit criteria | Estimate |
|---|---|---|---|---|
| M0 — Data-access baseline | Port minimal donor fetch/parsing slices into a temporary development harness; capture sanitized response fixtures and adapter notes for all four providers; record license provenance and CLI versions. The harness is not a shipped CLI. | None | Each provider has an exact attempted path, field map, known failures, and either a verified live result or a precise unresolved issue. Prioritize proving Antigravity and Grok early. | 2–4 days |
| M1 — Native shell and domain | App target, core package, fixture provider, models, deterministic pressure selection, reset formatting, popover, settings shell, normal checks and CI. | M0 shapes; shell can proceed while live access is unresolved | Fixture-driven app runs on macOS 14 with no Dock tile, correct menu item, all display/error states, and tests for time/selection logic. | 3–4 days |
| M2 — Codex vertical slice | Real auth discovery, direct usage, reset-credit inventory, bounded app-server fallback, credential-expiry behavior. | M0 + M1 | Correct live Codex windows and exact resets, including recovery and credits-with-usage partial success. First daily-usable build. | 2–3 days |
| M3 — Claude and shared refresh | Claude adapter, backoff, account guards, partial results, one scheduler, atomic cache, offline startup. | M2 | Codex and Claude work independently; repeated Refresh is bounded; stale and reset-boundary behavior passes deterministic tests. Internal two-provider preview. | 3–4 days |
| M4 — Antigravity | Local quota summaries, shared groups, `agy` detection/lifecycle, source completeness and scope checks. | M0 + M3 | Correct live Antigravity data with app open and with signed-in CLI only; absent data stays unknown. Three-provider MVP if previous providers pass. | 3–5 days |
| M5 — Grok | CLI auth, credits-proxy request, plan/reset interpretation, only necessary verified fallback. | M0 + M3 | Real included usage agrees with the vendor display; no spend-cap substitution; all four adapters pass their acceptance cases. | 2–4 days |
| M6 — Ship | Finish settings, launch at login, accessibility and supported-OS QA, eight-hour soak, release packaging, signing/notarization, README and notices. | M4 + M5 | Downloaded notarized artifact installs and runs on a clean Mac; checks pass; all four provider results and remaining limitations are documented. | 3–5 days |

Expected baseline: **18–29 engineering days**, approximately four to six weeks. Provider work is the largest uncertainty. Commit by coherent milestone slices rather than accumulating the entire app in one change; push at those stopping points using the repository's normal workflow.

M0 produces `docs/adapters/{codex,claude,antigravity,grok}.md`, each covering exact permitted file/Keychain accesses, endpoints, headers, field mappings, tested CLI version, credential refresh owner, timestamp units, cooldown behavior, dashboard link, source revision, and sanitized fixture provenance. These notes precede full adapter implementation; naming does not block them.

## 9. Validation and completion evidence

Create meaningful regression tests for quota semantics and asynchronous behavior. Default tests use injected clocks, temporary credential locations, mocked HTTP/process transports, and synthetic identities; they must never fall back to the developer's real home or Keychain. Live comparisons are explicit integration checks and remain outside CI.

| Area | Required cases |
|---|---|
| Parsing | Unknown/null versus zero; numeric bounds; missing optional fields; malformed sibling buckets; extra vendor fields; new bucket IDs; duplicate shared pools; correct UTC units; raw quantity division |
| Reset correctness | Seconds versus milliseconds; ISO dates with/without fractions and explicit offsets; DST gaps/repeated hours; local midnight; timezone/clock changes; expired reset with failed refresh; new-window confirmation; credit count versus eligibility |
| Selection and presentation | Highest-pressure enabled window; ties; capped with unknown percent/reset; used versus remaining mode; stale exclusion; degraded global coverage; empty provider set; unknown usage with a known reset |
| Scheduler | Fake-clock interval boundaries; manual spam; simultaneous open/wake/timer triggers; 429 cooldown; per-provider deadlines; cancellation; non-cancelling sibling failures; optional enrichment failures |
| Credentials and cache | Missing/expired auth; denied or locked Keychain; MCP-only Claude payload; account changes mid-fetch; explicit profile paths; offline launch; atomic cache replacement; schema corruption; no private data persisted |
| Antigravity | Grouped 5h/weekly quotas; nested fractions; disabled bucket; model availability without quota; mismatched identity; app/CLI lifecycle; cold start; owner-aware helper cleanup |
| Grok | Included usage versus on-demand spending; period-only response; unknown/team entitlement; stale token; unavailable ACP extension; incompatible reset period |
| macOS | macOS 14 and current supported macOS; light/dark/high contrast; VoiceOver and keyboard; long dates/names; multi-display placement; sleep/wake; login-item state changed in System Settings; clean-Mac launch |

Use `bazel test //...` for the test graph. The scaffold copies Eudoxus 3's formatting/lint rules, Swift cognitive-complexity checker, JSCPD configuration, and Lefthook entry point. `npm run check` runs the normal lint, build, and test workflow; that workflow invokes jscpd. Never invoke jscpd separately or weaken lint/coverage/duplication settings to get a pass. Bazel owns build and test definitions; generated Xcode projects do not introduce a parallel build system.

For each provider, record a timestamped manual comparison with the vendor's own usage surface: account matched, percentage matched within displayed rounding, reset instant matched, and source/version recorded without credentials. Exercise an actual naturally occurring reset boundary where possible; simulated clock tests cover all boundaries regardless of account usage. Do not consume quota or reset credits merely to manufacture a test.

Distribution uses a Developer ID signed, hardened-runtime application and Apple's [notarization workflow](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution), with the ticket stapled and Gatekeeper validation on the downloaded artifact. Target direct distribution without App Sandbox initially because the design reads vendor-owned local state and may spawn vendor tools. Build both arm64 and x86_64 if supported by the selected toolchain; record runtime coverage per architecture rather than equating a successful cross-build with testing.

Implement launch at login with [`SMAppService.mainApp`](https://developer.apple.com/documentation/servicemanagement/smappservice), displaying actual registration/approval state. Start with manual release downloads; Sparkle and Homebrew are later work. Do not change repository visibility as a side effect of development. The shipping name is Rations; finalize the production bundle identifier before external beta packaging.

Final release checklist:

- [ ] All four named subscription integrations return real, correctly scoped data on supported accounts.
- [ ] Each exposed reset has a trustworthy local calendar date/time; absent or elapsed data is labeled accurately.
- [ ] Reset credits, if exposed, retain their true scope and never imply unverified eligibility.
- [ ] One failed provider cannot blank the others or leave a confident stale menu percentage.
- [ ] Polling, retry, cache, identity-change, and process-lifecycle tests pass through the normal workflow.
- [ ] Native settings, keyboard/VoiceOver access, offline behavior, sleep/wake, and launch at login pass manual checks.
- [ ] Eight-hour resource measurements include app-owned helpers and show no accumulating processes or memory.
- [ ] The notarized artifact works from a clean installation; README lists supported versions and exact local accesses.
- [ ] Copied source has provenance and required notices; no credentials or personal account data appear in fixtures or logs.

## 10. Decisions to resolve during implementation

| Decision | Working choice | When it must be settled |
|---|---|---|
| Shipping name and bundle ID | Rations; `com.rawcontext.rations` / `com.rawcontext.rations.dev`; Raw Context team `U65DCW9TAK` | Confirmed |
| App source license | MIT for original code, preserving upstream notices | Before the first code import |
| Antigravity fallback breadth | App service plus installed `agy`; add remote access only for a demonstrated coverage gap | M0/M4 |
| Grok fallback breadth | Credits proxy first; only adopt another bearer/CLI source when necessary and proven | M0/M5 |
| CLI compatibility floor | Record exact tested versions and capability checks rather than guessing minimum versions | M0, then release QA |
| Distribution architecture coverage | Universal build where toolchain support permits; validate each claimed runtime architecture | M6 |

These decisions do not block starting the source ports and native fixture shell. The first deliverable should prove the exact numbers and reset timestamps we can obtain from the user's subscriptions, then carry that same normalized data through to the menu bar.
