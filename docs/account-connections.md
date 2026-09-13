# Live account connections

Rations reads subscription usage from vendor sign-ins on this Mac. It does not
send prompts, consume inference credits to measure quota, or use API spending as
a substitute for subscription allowance. No sample accounts ship in the app.

## Sources

| Provider | Sign-in source | Usage source |
| --- | --- | --- |
| Codex | `CODEX_HOME/auth.json`, default `~/.codex/auth.json` | `GET https://chatgpt.com/backend-api/wham/usage` with bearer and account ID headers |
| Claude | Claude Code credentials file or `Claude Code-credentials` Keychain service; native `claude auth status` fallback | OAuth `/api/oauth/profile` and `/api/oauth/usage` at `api.anthropic.com`; built-in `/usage` in a bounded safe-mode PTY when the OAuth store is unavailable |
| Antigravity | `agy`'s Keychain entry: service `gemini`, account `antigravity` | `loadCodeAssist`, then `retrieveUserQuotaSummary` at `cloudcode-pa.googleapis.com/v1internal` |
| Grok | `~/.grok/auth.json` | `GET /v1/billing?format=credits` and `/v1/settings` at `cli-chat-proxy.grok.com` |

Antigravity uses the Antigravity sign-in and quota product, not Gemini CLI. Its
legacy Keychain service and protocol metadata include the word `gemini`.
Both Antigravity requests require the vendor user-agent header. The code-assist
request also includes Antigravity IDE metadata. Without those values, Google can
return a different product's licensing error for a valid Antigravity subscription.
When the native token expires, `agy models` renews it before Rations rereads Keychain.
This lists models without running inference.

Codex primary windows are classified by their returned duration: a primary window
can be weekly. Additional model limits belong to the same account. Antigravity
keeps the shared model groups reported by its API. Every account gets one menu row;
all returned groups appear in its hover detail. The account row uses the main pool,
or the tightest returned window for each period when there are several model pools.

## Adding and retaining accounts

Open Settings → Accounts → Add Another Account for any provider. Sign in through
the vendor tool and choose Connect Current Account, or import its sign-in JSON.
Existing account records stay in Rations' Keychain service. Imported Claude OAuth
credentials are identified through their authenticated profile, independent of the
currently signed-in CLI account. Duplicate accounts are rejected; aliases persist.

Rations discovers changes to the active native sign-in during refresh. It does not
switch or log out vendor tools in the background. Reconnect reads the current
vendor sign-in and verifies the account identity before replacing credentials.
If an inactive saved token expires, sign in to that account in the vendor tool and
reconnect it. Rations does not independently rotate copied vendor refresh tokens.
Claude's CLI-only fallback can read only its active account; inactive CLI-only
accounts require a matching sign-in or an exported OAuth credential.

## Refresh, storage, and failure behavior

- Polling follows the refresh setting. Opening the menu requests a refresh when
  at least a minute has elapsed. Manual refresh shares the same one-minute gate.
- Providers fetch independently; one failure does not discard successful readings.
  The current refresh publishes after the pending provider requests complete.
- HTTP 429 respects `Retry-After` seconds or HTTP dates. Cached readings remain
  visible on failure, clearly marked stale, and are excluded from the aggregate.
- The static icon never changes shape. Its tooltip averages available percentages
  across accounts after combining independent pools within each account.
- Credentials and last readings are stored under the exact Keychain service
  `com.rawcontext.rations.accounts`. Display preferences use UserDefaults.
  Keychain enumeration requests attributes first, then reads each scoped item.
- HTTP uses ephemeral sessions without cookie storage or redirects. Network errors
  never log bearer tokens or response bodies. Vendor subprocesses are bounded,
  run in an app-owned directory, and are stopped when Rations quits.

## Verified behavior and limitations

On September 13, 2026, the signed development app loaded real Codex Pro, Claude
Max, Google AI Pro through Antigravity, and SuperGrok Heavy accounts. Codex,
Claude, and Antigravity returned live percentages and reset dates.

Grok returned a weekly reset and subscription tier but omitted
`creditUsagePercent`. Its CLI billing logs confirmed the same omission after a
real model call. The CLI session `usage.json` contained token counts and estimated
cost, without a subscription allowance. Rations therefore shows unknown usage
with the known reset. If Grok returns the percentage later, it is parsed normally.
An unknown percentage is informational and does not trigger a reconnect warning.

The current adapters depend on vendor CLI credential formats and private usage
endpoints; they may need updates when those contracts change. Expired inactive
credentials require reconnecting. Automatic account switching, Developer ID
distribution, notarization, and independent OAuth onboarding remain future work.

## Validation and diagnostics

`npm run check` includes synthetic parser cases, account identity checks, saved
record round trips, terminal redraws, malformed/missing quota handling, mocked HTTP
requests and errors, reset dates, and refresh cooldowns. Tests never query real
Keychain entries, CLI sessions, or provider endpoints.

For a local signed smoke check:

```sh
./script/build_and_run.sh --signed --settings --verify --connection-report "$PWD/dist/connections.json"
```

The optional report includes provider, plan, errors, quota percentages, and reset
dates. It excludes credentials, account IDs, emails, and CLI output. `dist` is
ignored by Git. The running app updates this report after each state publication.

## Research provenance

Wire contracts were checked against installed vendor tools and the MIT-licensed
[CodexBar source at afa483f2](https://github.com/steipete/CodexBar/tree/afa483f2a287ebb999adbfaa060a2c3d0cfa1cc8/Sources/CodexBarCore/Providers).
Rations implements its own transport, credential storage, parsers, and native UI.
The relevant reference adapters are Codex OAuth usage, Claude OAuth profile/usage,
Antigravity remote quota summary, and Grok credits proxy. Do not copy vendor token
values, user CLI logs, or live account responses into regression fixtures.
