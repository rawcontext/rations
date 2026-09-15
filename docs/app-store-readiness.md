# Mac App Store readiness

Reviewed September 14, 2026 (America/Chicago).

**Rations is not ready for Mac App Store submission.** The current development
app works outside App Sandbox. Its provider access needs an architectural change
before a sandboxed release can preserve the existing features.

## Release blockers

| Area | Repository evidence | Work needed |
| --- | --- | --- |
| App Sandbox | `Resources/Development.entitlements` contains application/team identifiers only. | Implement and test sandbox-compatible provider connections, then enable the sandbox and required scoped capabilities. Simply adding an entitlement would break existing integrations. |
| External dependencies | `VendorExecutable`, `CredentialDiscovery`, and `CursorAppAuth` use separately installed CLIs, vendor Keychain entries, home-directory credentials, and Cursor's database. | Replace these dependencies with permitted, self-contained sign-in and quota sources. Document which providers can support this before committing to feature parity. |
| Service authorization | `ProviderFetcher` calls private vendor usage endpoints with copied native credentials. | Establish permission for each integration and its authentication method. No provider authorization evidence is present in this repository. |
| Distribution signing | Bazel's signed Release configuration still selects a development provisioning profile. | Add Mac App Store distribution signing, packaging, upload validation, and a tested installation from TestFlight. A production bundle identifier alone is insufficient. |
| Privacy policy | No published Rations policy or in-app policy link exists. | Publish a policy describing storage, vendor requests, retention/removal, and contact details; link it from Settings and App Store Connect. |
| Store assets | There is no application icon asset catalog. Only the menu-bar glyph is drawn in code. | Supply the release app icon, screenshots, support URL, store description, review instructions/access, and required App Store Connect answers. The About GitHub link intentionally points to the future `rawcontext/rations` repository. |

Apple requires sandboxing and self-contained Mac App Store apps; login startup
needs consent. See [review guideline 2.4.5](https://developer.apple.com/app-store/review/guidelines/#hardware-compatibility).
Apple's [sandbox configuration](https://developer.apple.com/documentation/xcode/configuring-the-macos-app-sandbox)
and [file-access guidance](https://developer.apple.com/documentation/security/accessing-files-from-the-macos-app-sandbox)
describe the platform boundary. Helpers inherit sandbox restrictions; launching
an external CLI is not a way around them.
[Sandbox diagnostics](https://developer.apple.com/documentation/security/discovering-and-diagnosing-app-sandbox-violations)
must be part of the integration migration.

Third-party service access must be permitted under the provider's terms
([guideline 5.2.2](https://developer.apple.com/app-store/review/guidelines/#intellectual-property)).
Anthropic expressly restricts third-party Claude.ai login and routing users'
subscription credentials; the present adapter needs a permitted integration or
provider approval before distribution.
[Anthropic's authentication terms](https://code.claude.com/docs/en/legal-and-compliance#authentication-and-credential-use)
are a concrete blocker, not evidence that another quota app's implementation is approved.

Privacy-policy links are required in the app and metadata
([guideline 5.1.1](https://developer.apple.com/app-store/review/guidelines/#privacy)).
Complete privacy, export-compliance, age-rating, category, and distribution details
in [App Store Connect](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/).
Account settings, agreements, and existing store records were not inspected in this review.

## Implemented or verified locally

- New preferences refresh every 15 minutes. Opening the menu respects that interval;
  explicit Refresh remains available and honors provider cooldowns. Existing saved
  user choices are preserved.
- Launch at login is opt-in: `LoginItemManager` reads `SMAppService` status at
  initialization and registers only when the user enables the toggle.
- Added `PrivacyInfo.xcprivacy` with the app's UserDefaults reason `CA92.1` and no
  tracking. This declares app-owned preferences; it is not a completed App Store
  privacy questionnaire or permission to read other apps' data.
  [Apple's required-reason definitions](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)
- The bundle declares the Utilities category, macOS 14 minimum, and version/build
  values. Production identity remains `com.rawcontext.rations`, team `U65DCW9TAK`.
- Usage requests use HTTPS, ephemeral sessions, no shared cookie store, and no
  redirects. Account records use Keychain; diagnostics omit credentials and identities.
- Provider errors distinguish authentication, access approval, cooldown, transient
  refresh failure, and initial verification. Expired reset countdown labels are removed.
- Added About Rations with version information, repository tagline, future GitHub
  destination, and linked company copyright. Settings has flatter pane controls and
  the standard Command–Comma menu action.

## Required release validation

For this change, `npm run check` passed all lint/build checks and all four test
targets, including 111 app/core/provider test cases. The signed development app
rebuilt and launched successfully; its code signature and bundled privacy manifest
validated. Live diagnostics showed Claude and Grok recovering without browser
login; Antigravity remained blocked by native Keychain approval. This was not a
sandboxed build, an App Store upload, or a completed cross-version/UI acceptance test.

After the blockers are resolved, validate a clean sandboxed installation without
vendor tools; every supported provider's login, expiry recovery, removal, and error
states; opt-in login startup; offline/wake behavior; VoiceOver/keyboard access;
and supported macOS versions. Current local validation uses macOS 27 beta and
Xcode 27 beta, so it does not establish runtime compatibility on macOS 14.

Use an Xcode/SDK build accepted for customer distribution at submission time.
Keep the repository's development toolchain unchanged until the release toolchain
is selected and tested. Validate the actual upload through Apple's distribution
workflow; do not infer acceptance from a local Bazel build.
[Apple's upload requirements](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/)

Developer ID signing and notarization would support a separate direct-distribution
release. They do not satisfy the Mac App Store sandbox or service-authorization requirements.
