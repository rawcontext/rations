# Rations

A native Swift macOS menu bar app for subscription usage and reset times across
Codex, Claude, Antigravity, Grok, and Cursor.

The native UI follows the [authoritative v6 design](docs/design/README.md):
compact account rows, stacked quota meters, hover submenus, and General/Accounts/Providers
Settings. Rations discovers existing vendor sign-ins, reads live usage, and saves
connected accounts in Keychain. See [account connections](docs/account-connections.md)
for supported sources, refresh behavior, and provider limitations.

Every provider has its own multi-account section with shared add/rename/remove
controls. Each account has one menu row; model-specific quotas appear inside its
hover detail. The menu bar uses a static monochrome icon. Its tooltip averages
available quota across connected accounts, combining independent pools within an
account first. The summary updates when readings change without double-counting
overlapping windows. Expired or incomplete readings remain unknown until a provider
publishes current data.

## Install

[Download Rations for macOS](https://github.com/rawcontext/rations/releases/latest/download/Rations.dmg),
open the disk image, and drag Rations into Applications. Requires macOS 14 or later
on Apple Silicon or Intel. Connect your installed vendor tools from Settings.
Direct downloads include signed updates through Sparkle.

## Development setup

Use macOS with **Xcode 27 beta** installed and its first-launch setup completed.
The application deployment target is macOS **14.0**. Bazel uses the full Xcode
toolchain; Command Line Tools alone are insufficient.

The `tools/bazel` Bazelisk wrapper selects `/Applications/Xcode-beta.app` for this
project without changing the system-wide Xcode selection. If your beta is installed
elsewhere, export `DEVELOPER_DIR` with its `Contents/Developer` path. `.bazelrc`
requests the Xcode 27.0 toolchain.

Install Bazelisk (`brew install bazelisk`) and the tools pinned in
[.tool-versions](.tool-versions): Node.js 26.8.2, SwiftLint 0.65.1, and ShellCheck
0.11.0. With the corresponding asdf plugins installed, run `asdf install`.
Bazelisk reads Bazel 9.2.0 from `.bazelversion`.

```sh
./scripts/bootstrap.sh
npm run check
npm run dev
```

Bootstrap installs the pinned repository tooling and Lefthook pre-commit hook.
The Node dependencies are development tools only; the app ships no JavaScript
runtime. Tests use synthetic data and mocked HTTP; they do not access your accounts.

The commands below use `npm run` so they always resolve the repository-local pnpm
and lint executables, independently of any global pnpm installation.

## Commands

| Command | Purpose |
| --- | --- |
| `npm run build` | Build the app and shared Swift packages with Bazel |
| `npm run test` | Run app lifecycle, quota, provider, transport, and lint-tool tests |
| `npm run lint` | Run the complete Eudoxus 3-derived lint policy, including JSCPD |
| `npm run check` | Lint, build, and test the repository |
| `npm run dev` | Stop the existing Rations process, build, and launch the `.app` |
| `npm run dev -- --signed --settings` | Open Settings with real account connections |
| `npm run dev -- --signed` | Build and run with Raw Context's local development signing profile |
| `./scripts/build_and_run.sh --verify` | Build, launch, and verify the process is running |
| `./scripts/build_and_run.sh --debug` | Build and launch under LLDB |
| `./scripts/build_and_run.sh --logs` | Launch and stream process logs |
| `./scripts/build_and_run.sh --telemetry` | Launch and stream the Rations log subsystem |
| `npm run xcode` | Generate the Xcode project from Bazel targets |
| `bazel test //packages/core:test` | Run the quota model tests during development |
| `bazel build --config=release //apps/macos:app` | Build an optimized production bundle without distribution signing |
| `npm run release:prepare` | Build the universal production app with Sparkle |
| `npm run release` | Sign, notarize, staple, and package the DMG and update feed |
| `npm run release:publish` | Publish and verify the prepared GitHub release |

Rations intentionally has no Dock icon or main window. Click the pie icon in
the menu bar to open it, then choose Settings or Quit. The development bundle is
staged at `dist/Rations.app`. Launches show real data or an explicit disconnected,
stale, or unknown state. Preview mode and sample accounts have been removed.

Development uses `com.rawcontext.rations.dev`; `--config=release` uses
`com.rawcontext.rations`. Xcode Debug and Release use Raw Context LLC's team
`U65DCW9TAK` and a local Mac development profile. Ordinary Bazel/CI builds remain
ad-hoc signed; add `--config=signed` for team signing. See
[signing configuration](tools/apple-signing/README.md). For direct downloads,
Developer ID signing, notarization, and Sparkle updates, use the
[release workflow](docs/releases.md).

## Monorepo boundaries

```text
apps/macos/                 Native menu, SwiftUI account detail/settings, bundle resources
packages/core/              Provider IDs and normalized quota data; no UI dependencies
packages/providers/         Live vendor adapters, credential discovery, Keychain, refresh
tools/cognitive-complexity/ SwiftSyntax-based lint tool and its regression tests
tools/testing/              Xcode framework environment for Bazel tests
scripts/                    Bootstrap, repository checks, and native app build/run/debug
docs/                       Development policy and implementation references
```

Bazel is the source of truth for builds and dependencies. `MODULE.bazel.lock`
records the resolved module graph. `pnpm-lock.yaml` owns development-only npm
dependencies. Generated Xcode projects are ignored; run `npm run xcode` again after
changing BUILD files and open `apps/macos/Rations.xcodeproj`.

Add core behavior to `packages/core`, vendor transport code to `packages/providers`,
and presentation to `apps/macos`. Declare direct Bazel dependencies and retain
private package visibility. Do not add a parallel SwiftPM or hand-maintained Xcode
build definition for the same targets.

See [the lint policy](docs/linting.md) for the copied rules, provenance, and limits.
All pre-commit checks are read-only; fix and stage failures before retrying a commit.

## License

Rations source code is available under the [MIT license](LICENSE).
Third-party code retains its own notices. The menu glyph is adapted from
CC BY-SA 4.0 artwork; see [icon attribution](apps/macos/Resources/IconAttribution.txt).
Bundled notices are available in About Rations → Acknowledgments.
