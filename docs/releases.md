# Direct Mac distribution

Rations ships from [GitHub Releases](https://github.com/rawcontext/rations/releases)
as a Developer ID signed, hardened-runtime, notarized disk image. It does not use
the Mac App Store. The production bundle is `com.rawcontext.rations` under Raw
Context LLC's team `U65DCW9TAK`.

## Release commands

```sh
npm run release:prepare
npm run release
npm run release:publish
```

`release:prepare` builds the production bundle through Bazel for Apple Silicon
and Intel, stages it at `dist/release-work/Rations.app`, and verifies identity,
architectures, update configuration, and bundled notices. This local preparation
step does not produce a publicly distributable installer by itself.

`release` requires committed source. It runs `npm run check`, rebuilds the
production app, verifies credentials, signs nested code from the inside out,
notarizes and staples the app, creates a DMG with an Applications shortcut,
signs/notarizes/staples the DMG, and generates the signed Sparkle appcast.
Results go in `dist/releases/<version>/`. Existing release directories are never
silently replaced. Apple submission receipts are retained for troubleshooting.

`release:publish` checks the source commit, artifact checksums, notarization ticket,
and update signatures. It pushes the source/tag, creates the GitHub release,
downloads the published DMGs, and compares them with the verified installer.
Run it only after reviewing the release notes and installer. Publishing is an
explicit command; preparation and signing never publish automatically.

The versioned DMG is used by Sparkle. The identical `Rations.dmg` asset provides
a stable GitHub download link:

`https://github.com/rawcontext/rations/releases/latest/download/Rations.dmg`

Update `CFBundleShortVersionString` and monotonically increase `CFBundleVersion`
in `apps/macos/Resources/Info.plist` for each release. Add matching release notes
under `releases/<version>.md` before committing.

## Signing prerequisites

- Xcode 27 beta through the project toolchain and pinned repository tools.
- A valid `Developer ID Application: Raw Context LLC (U65DCW9TAK)` identity,
  including its private key, in Keychain. App Store distribution certificates
  cannot substitute for Developer ID.
- A `notarytool` Keychain profile named `Rations`. Configure it with a team API
  key that is authorized for notarization:

```sh
xcrun notarytool store-credentials Rations \
  --key /private/path/AuthKey_KEYID.p8 \
  --key-id KEYID --issuer ISSUER_ID
```

The private key is never embedded in the app or committed. `RATIONS_NOTARY_PROFILE`
can select another configured profile. `RATIONS_SIGNING_IDENTITY` can select a
different valid Developer ID Application certificate from the same team.

## Sparkle

Sparkle 2.10.0 is pinned by SHA-256 in `MODULE.bazel` and imported as a dynamic
framework through Bazel. Its updater, helper tools, and framework are signed
with the application's Developer ID while retaining required helper entitlements.

The update-signing key uses Keychain account `com.rawcontext.rations`. The public
key is embedded in `Resources/Distribution.plist`; release preflight checks that
the local key matches. Use Sparkle's `generate_keys --account com.rawcontext.rations`
to manage that key, and keep its private material in Keychain.

Production builds check for updates automatically and provide Check for Updates
in both menus. Installation remains user-confirmed. System profiling is disabled.
Update archives are verified before extraction, and appcasts must be signed.
Development builds do not start Sparkle or point to the production feed.

Both the appcast and DMGs are hosted as GitHub release assets. Homebrew packaging
is a later distribution option; there is no cask to install yet.

## Validation and notices

`npm run check` includes synthetic release validation tests in `//tools/release:test`.
They reject development bundle identities, unsuitable signing identities,
mismatched update URLs/sizes, and verify nested signing order without touching
real credentials. The release command additionally validates actual signatures,
Apple tickets, and update signatures.

Runtime coverage on the build Mac is separate from Intel cross-compilation and
macOS 14 compatibility testing. Record those limits in release notes; do not
claim that cross-building is an Intel runtime test.

The app bundles Rations' MIT license, Sparkle's notices, the notice for Cursor
code adapted from CodexBar, and the CC BY-SA icon attribution. About Rations →
Acknowledgments exposes only these shipped materials. Research references alone
do not create product acknowledgments.

References: [Apple's Developer ID workflow](https://developer.apple.com/developer-id/),
[notarization](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow),
and [Sparkle setup](https://sparkle-project.org/documentation/).
