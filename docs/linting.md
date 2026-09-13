# Development checks

The quality baseline comes from the sibling `ccheney/eudoxus3` project, copied on
13 September 2026. `.jscpd.json`, `.swiftlint.yml`, `biome.json`, and `lefthook.yml`
are copied unchanged. `scripts/lint.sh` also checks the extensionless `tools/bazel`
shell wrapper; its checks and thresholds are unchanged. The SwiftSyntax cognitive-complexity tool,
its tests, and the Xcode test environment wrapper are also reused. The checker
test target adds visibility for the root test suite; its scoring rules are unchanged.

The donor's most recent commit touching the copied lint policy was `ddd176d`
(`Exclude generated Lefthook launchers from duplicate checks`). No dependency on
the sibling checkout is needed after cloning Rations.

## Normal workflow

`pnpm lint` is the supported lint entry point. Lefthook invokes that same command
before every commit using the repository-local pnpm executable. It runs Biome,
Buildifier, ShellCheck, SwiftLint, the Swift cognitive-complexity checker, and JSCPD.
`pnpm check` additionally builds all application/library targets and runs tests.

Checks examine tracked and untracked source across the repository. They do not
edit or auto-stage files. Lefthook hides unstaged changes in partially staged files
while running; stage fixes before committing again. CI uses the same `pnpm check`.

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
| JS/TS cognitive complexity | 15 |
| JS/TS function/file length | 50 / 350 lines |
| JS/TS classes | 1 per file |
| JSCPD duplication | 0%, minimum 5 lines and 50 tokens |

SwiftLint recommended defaults and the donor's additional SwiftUI/concurrency
rules remain enabled. Warnings fail under strict mode. Biome retains the donor's
future JS/TS rules even though application code is Swift.

The custom checker measures nesting-sensitive Swift syntax complexity; it is not
a claim of exact SonarQube compatibility. Its regression tests cover branching,
nesting, boolean operators, recursion, ternaries, and diagnostic locations.

## Duplication policy

JSCPD retains strict mode, blame, broad format coverage, the `ai` reporter, and
the donor's zero threshold. No language allowlist removes Swift from checking.
The inherited ignore list covers generated/dependency outputs and the donor's
design-handoff path; those unused paths do not create source exclusions here.
Tests and handwritten code stay included.

Run JSCPD through `pnpm lint` or the pre-commit hook, never as a separate manual
workflow. Fix reported duplication before committing. Do not use hook bypasses,
baselines, relaxed limits, or added source ignores to force a pass.

## Tool versions

Versions were checked against the npm registry, Bazel Central Registry, and the
upstream release APIs before installation. npm tools are pinned in `package.json`
and `pnpm-lock.yaml`; native lint tools are pinned in `.tool-versions`; Bazel and
its rules are pinned in `.bazelversion`, `MODULE.bazel`, and the module lockfile.
CI selects Xcode 27 beta, matching `.bazelrc` and the local toolchain family.
