# AGENTS.md

## Scope and completion

- Direct user instructions take precedence over this file and skill guidance, subject to system and developer requirements.
- For substantial tasks, briefly state the intended outcome, material assumptions, and how completion will be verified. Routine edits do not need a formal plan.
- Resolve routine implementation choices from the request and repository evidence. Ask when missing information materially changes scope, correctness, or authorization; continue independent work while waiting.
- Carry authorized work through implementation, relevant validation, and fixes for failures caused by the change. When the request includes running or inspecting the result, do that before reporting completion.
- Inspection, local edits, and checks using confirmed isolated, non-production fixtures may proceed without repeated approval. Ask before destructive operations or production changes unless already authorized.
- If an instruction blocks progress, identify its source and exact requirement, explain the unresolved decision, and report what remains unfinished.

## Context and research

- Start with the code, tests, and configuration relevant to the change. Expand exploration when dependencies or uncertainty require it.
- Read documentation and skills for the workflow at hand; load supporting references only as needed. Do not require a full repository map or unrelated documents before every edit.
- Use Context7 for library, service, and API documentation when implementing or changing integrations. Verify uncertain syntax, patterns, and version compatibility with authoritative web sources.
- Verify today's date when the task depends on current information, dates, or versions.

## Simplicity and boundaries

- Implement the simplest solution that meets the request. Avoid speculative features, configurability, single-use abstractions, and error handling for impossible scenarios.
- Keep changes focused; match the surrounding style and leave unrelated code, formatting, and pre-existing dead code alone. Remove imports, variables, and helpers made unused by your changes.
- Keep files focused on one responsibility, favor composition and cohesive modules, and keep domain logic testable in isolation.
- Treat roughly 300–350 lines as a cue to reassess cohesion, not an automatic stopping point. Split distinct responsibilities and briefly explain meaningful boundary changes before implementing them.
- Prefer self-documenting code. Add comments only to explain non-obvious reasons.

## Validation

- Choose checks appropriate to the changed behavior and risk. Add or update tests when they provide meaningful regression coverage; documentation-only edits do not require application tests.
- Run the affected checks and any checks required by the repository workflow. Fix failures caused by the change and rerun affected checks. Broaden or repeat validation only for new changes, failures, or unresolved concerns.
- Report what was verified and any checks that could not run. Do not claim success for checks that were skipped or unavailable.
- Do NOT modify linting rules or code coverage requirements without explicit approval.

## Duplicate-code policy

- Rely on the normal project lint and Lefthook pre-commit workflows to invoke jscpd automatically; do not run jscpd manually.
- Treat every jscpd failure surfaced by those workflows as an error that must be fixed before commit.
- Refactor the reported duplication, then rerun the normal project workflow.
- Never resolve a finding by weakening thresholds, narrowing format coverage, or adding an ignore unless the ignored file is generated or vendored and the exclusion is narrowly justified.

## Package versions

- Before installing or updating a package, check its current version on the authoritative registry (npm, crates, etc.). Do not assume an installed version is current.
- Install the latest stable version unless a specific incompatibility requires an older one; document that incompatibility.

## Development baseline

- The authoritative UI is `docs/design/ui-screens/project/Rations v6.dc.html`; read `docs/design/README.md` for its scope and precedence over older product notes.
- Bundle IDs are `com.rawcontext.rations` (production) and `com.rawcontext.rations.dev` (development). Use Raw Context LLC signing team `U65DCW9TAK`.
- Rations is a native Swift macOS menu bar app. The checked-in `Rations.xcodeproj` owns the app build; Swift Package Manager owns shared Swift modules and external dependencies. Open the project directly with `make xcode`.
- Keep the app in `apps/macos`, UI-independent models in `packages/core`, and vendor adapters in `packages/providers`. Declare direct dependencies in the Xcode target and Swift package manifests.
- Use Xcode 27 beta through the Makefile. `DEVELOPER_DIR` can select a differently located beta installation. The application deployment target remains macOS 14.0.
- Use the Makefile for all commands: `make check` for repository lint/build/tests and `make dev` for the native build/run loop. The Run button uses `scripts/build_and_run.sh`, which invokes `make build`.
- The Eudoxus 3-derived lint policy and thresholds are documented in `docs/linting.md`; retain them when adding source or tooling.

## Git workflow

- Do not prefix branches with `codex/` or add `[Codex]` to PR titles or descriptions.
- Commit thematically and push at coherent stopping points without asking. If no remote is configured, commit locally and report that pushing is unavailable.

## Maintaining these instructions

Keep durable repository constraints here and workflow details in relevant documentation or skills. When revising guidance, remove stale claims, duplication, and unnecessary stop conditions. Keep instructions useful across the models contributors use.

Reference: [Rethinking skills and prompts for GPT-6 Astra](https://developers.openai.com/blog/rethinking-skills-and-prompts-for-gpt-6-astra).
