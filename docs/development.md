# Development

Rations uses a checked-in Xcode project for the macOS application and Swift Package
Manager for shared code and dependencies. Open `Rations.xcodeproj` directly; no
project generation is needed. Xcode and command-line builds use the same targets.

## Setup

Install Xcode 27 beta and complete its first-launch setup. Command-line builds
select `/Applications/Xcode-beta.app` without changing the system-wide Xcode
selection. Set `DEVELOPER_DIR` if Xcode is installed elsewhere. The app's minimum
supported system remains macOS 14.

Install the tools pinned in `.tool-versions`: SwiftLint, ShellCheck, and GitHub CLI.
Bootstrap downloads checksum-verified native JSCPD and Lefthook executables for
your Mac into `.build/tools`. No Node or JavaScript package manager is required.
Then run:

```sh
make bootstrap
make check
make dev
```

All commands are exposed through the Makefile. `make` lists them.

| Command | Purpose |
| --- | --- |
| `make build` | Build a Debug app with local ad-hoc signing |
| `make build SIGNED=1` | Build with Raw Context's development signing team |
| `make build CONFIGURATION=Release` | Build an optimized production bundle |
| `make test` | Run Swift package, app lifecycle, lint-tool, and release tests |
| `make test-packages` | Run quota model and provider tests |
| `make lint` | Run SwiftLint, cognitive complexity, ShellCheck, and JSCPD |
| `make check` | Lint, build, and run all tests |
| `make dev` | Build and launch the development app |
| `make dev SIGNED=1 ARGS=--settings` | Open Settings with development team signing |
| `make verify` | Build, launch, and confirm the process stays running |
| `make debug` | Build and launch under LLDB |
| `make logs` | Launch and stream process logs |
| `make telemetry` | Launch and stream development subsystem logs |
| `make xcode` | Open the checked-in Xcode project |
| `make archive` | Create an unsigned universal Release archive |
| `make release-prepare` | Build and validate the production app |
| `make release` | Sign, notarize, staple, and package the release |
| `make release-publish` | Publish and verify the prepared GitHub release |

Build products and SwiftPM downloads live under `.build/`. The development launch
script stages the app at `dist/Rations.app`; the desktop Run button invokes the
same script and Makefile build. Tests use synthetic data and mocked HTTP.

## Code organization

- `apps/macos`: native menu, SwiftUI settings, services, and bundle resources.
- `packages/core`: UI-independent quota models.
- `packages/providers`: vendor adapters, credential discovery, and refresh logic.
- `packages/Package.swift`: shared library products, dependencies, and tests.
- `tools/cognitive-complexity`: a separate SwiftPM command-line tool and tests.
- `tools/release`: release validation, signing, notarization, and packaging.

The app's Sources folder is synchronized with Xcode, so new Swift files are picked
up automatically. Keep package dependencies explicit in `Package.swift`. Sparkle
is pinned in the Xcode project's package reference and `Package.resolved`;
SwiftSyntax is pinned by the lint tool's package manifest and lockfile.

Debug uses `com.rawcontext.rations.dev`; Release uses `com.rawcontext.rations`.
Xcode uses Raw Context LLC team `U65DCW9TAK` with automatic development signing.
Makefile builds default to ad-hoc signing so local checks and CI do not require
private signing assets. See [signing](../tools/apple-signing/README.md),
[release steps](releases.md), [lint policy](linting.md), and
[account connections](account-connections.md).
