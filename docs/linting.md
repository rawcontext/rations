# Development checks

The Swift and duplicate-code quality baseline comes from the sibling
`ccheney/eudoxus3` project, copied on 13 September 2026. SwiftLint thresholds,
SwiftSyntax cognitive-complexity scoring, and JSCPD's zero-duplication policy
remain intact. The cognitive checker and its regression tests use Swift Package
Manager. Lefthook invokes the Makefile's lint target before commits.

## Normal workflow

`make lint` is the supported lint entry point. Lefthook invokes that same command
before every commit. It runs ShellCheck, SwiftLint, the Swift cognitive-complexity
checker, and JSCPD.
`make check` additionally builds all application/library targets and runs tests.

Checks examine tracked and untracked source across the repository. They do not
edit or auto-stage files. Lefthook hides unstaged changes in partially staged files
while running; stage fixes before committing again. CI uses the same `make check`.

| Check | Maximum |
| --- | --- |
| Swift physical file length | 350 lines |
| Swift type body | 250 code lines |
| Swift function/accessor/initializer body | 50 code lines |
| Swift closure body | 30 code lines |
| Swift function parameters | 5 |
| Swift cyclomatic complexity | 10, including switch cases |
| Swift cognitive complexity | 15 |
| Swift peer top-level declarations | 1 per file |
| Swift nested types/functions | 1 level |
| Swift line length | 120 characters, URLs exempt |
| JSCPD duplication | 0%, minimum 5 lines and 50 tokens |

SwiftLint recommended defaults and the donor's additional SwiftUI/concurrency
rules remain enabled. Warnings fail under strict mode.

The custom checker measures nesting-sensitive Swift syntax complexity; it is not
a claim of exact SonarQube compatibility. Its regression tests cover branching,
nesting, boolean operators, recursion, ternaries, and diagnostic locations.

## Duplication policy

JSCPD retains strict mode, blame, broad format coverage, the `ai` reporter, and
the donor's zero threshold. No language allowlist removes Swift from checking.
The ignore list covers dependency outputs, machine-maintained Xcode project
metadata and the vendored design handoff.
Tests and handwritten code stay included.

Run JSCPD through `make lint` or the pre-commit hook, never as a separate manual
workflow. Fix reported duplication before committing. Do not use hook bypasses,
baselines, relaxed limits, or added source ignores to force a pass.

## Tool versions

JSCPD 5.2.0 and Lefthook 2.1.14 are installed as native macOS executables by
`scripts/install-hook-tools.sh`, with pinned release URLs and SHA-256 checksums
for Apple Silicon and Intel. SwiftLint and ShellCheck are pinned in `.tool-versions`;
SwiftSyntax is pinned in the cognitive checker's `Package.swift` and
`Package.resolved`. CI selects Xcode 27 beta, matching the Makefile toolchain.
