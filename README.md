# Rations

A native Swift macOS menu bar app for subscription usage and reset times across
Codex, Claude, Antigravity, and Grok.

This repository currently contains the development scaffold: a runnable menu bar
app, settings shell, shared quota models, a provider interface, and build/lint/test
automation. Provider authentication and live quota fetching are future work in
[the implementation plan](IMPLEMENTATION_PLAN.md).

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
runtime. No provider credentials are accessed by the scaffold or its tests.

The commands below use `npm run` so they always resolve the repository-local pnpm
and lint executables, independently of any global pnpm installation.

## Commands

| Command | Purpose |
| --- | --- |
| `npm run build` | Build the app and shared Swift packages with Bazel |
| `npm run test` | Run the core and cognitive-complexity test suites |
| `npm run lint` | Run the complete Eudoxus 3-derived lint policy, including JSCPD |
| `npm run check` | Lint, build, and test the repository |
| `npm run dev` | Stop the existing Rations process, build, and launch the `.app` |
| `./script/build_and_run.sh --verify` | Build, launch, and verify the process is running |
| `./script/build_and_run.sh --debug` | Build and launch under LLDB |
| `./script/build_and_run.sh --logs` | Launch and stream process logs |
| `./script/build_and_run.sh --telemetry` | Launch and stream the Rations log subsystem |
| `npm run xcode` | Generate the Xcode project from Bazel targets |
| `bazel test //packages/core:test` | Run the quota model tests during development |
| `bazel build --config=release //apps/macos:app` | Build an optimized development bundle |

Rations intentionally has no Dock icon or main window. Click the gauge icon in
the menu bar to open it, then choose Settings or Quit. The development bundle is
staged at `dist/Rations.app`, uses `com.ccheney.rations.dev`, and is locally signed
for development. Release signing and notarization are separate future work.

The Codex app's Run action invokes the same build-and-run script.

## Monorepo boundaries

```text
apps/macos/                 SwiftUI entry point, popover, settings, bundle resources
packages/core/              Provider IDs and normalized quota data; no UI dependencies
packages/providers/         Async provider contract; future vendor adapters
tools/cognitive-complexity/ SwiftSyntax-based lint tool and its regression tests
tools/testing/              Xcode framework environment for Bazel tests
scripts/                    Bootstrap and repository checks
script/                     Native app build/run/debug entry point
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
