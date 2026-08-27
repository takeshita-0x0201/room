---
name: release-audit
description: Use when preparing to stage, push, or release Room, after a batch of feedback-driven changes, or when the user asks for a release audit, final audit, or pre-release audit. Also use before tagging a version, distributing a build through Homebrew, or opening the repo to the public.
---

# Room Pre-Release Audit

## Overview

Before any release step (staging / push / publishing), audit the entire codebase — **identify only, change nothing**.
The deliverable is a severity-ranked findings list. Fixes are dispatched separately by the PM.

## How to run

- Run as a **top-tier model subagent (fork preferred)**. If not a fork, first read: `docs/requirements.md` (functional spec of record), `docs/design-system.md` (UI design of record), `AGENTS.md`, `docs/backlog.md` (deferral ledger), and the latest `docs/verification-v0.1.md`.
- Scope: every Swift file under `Room/` and `RoomTests/`, plus `project.yml`, `docs/`, and root-level markdown.
- **Do not re-report settled items**: anything recorded in `docs/backlog.md`, or marked as a **[v1.x]** decision in the docs.
- Test command: `xcodegen generate && xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test`

## Distribution update verification

When the task includes a push or a user-facing build update, verify the complete distribution path. A successful local `xcodebuild` only updates Xcode DerivedData; it does not update `/Applications/Room.app` or an already-running Room process.

After pushing changes that affect `Room/**`, `project.yml`, or the release workflow:

1. Confirm the `Release to Homebrew` workflow ran for the pushed commit and completed successfully. Also confirm the CI workflow is successful when it was triggered.
2. Confirm the workflow published a GitHub release asset and updated the Homebrew tap Cask. Do not tell the user that the distributed build is updated while the release or tap update is still pending.
3. On a machine with the Cask installed, run `brew update`, then check `brew outdated --cask room` or `brew info room`. `brew update` refreshes formula/Cask definitions; it does not install a newer Room app by itself. If a newer Cask is available and updating the local installation is in scope, run `brew upgrade --cask room`.
4. If Room was running during the upgrade, terminate it gracefully and relaunch `/Applications/Room.app`; otherwise the old in-memory process may continue to serve the old build.
5. Verify `/Applications/Room.app/Contents/Info.plist` has the expected version/build number and that the running process command is `/Applications/Room.app/Contents/MacOS/Room`.

Use the project's Homebrew distribution as the user-facing update path. Do not replace it with a manual copy of a DerivedData app unless the user explicitly asks for a local development build. If the release workflow or tap has not completed, report that state and wait or continue monitoring rather than upgrading from a stale Cask.

## Audit sections (A–I all mandatory; write "none" explicitly where clean)

| # | Section | What to check |
|---|---|---|
| A | Implementation gaps | Cross-check every section and decision (D1–…) of requirements + design-system against the code, including silent divergence |
| B | Documentation consistency | Drift between requirements ↔ design-system ↔ README ↔ CONTRIBUTING ↔ extensions.md ↔ actual code. Features described that don't exist; stale UI descriptions |
| C | Safety-gate regression | Re-verify invariants: deletion only via the Review-gated single `cleanup.delete` call site / `delete` re-derives rules by ID (never trusts items) / symlink resolved-path containment / inode re-verification / per-item running-app re-check / Quit & Force Quit policy re-check + confirmation dialog / tests never touch real user data |
| D | Redundant & dead code | Unreferenced symbols/files (prove with grep), duplicated logic, unreachable branches, overlapping tests |
| E | Over-engineering (YAGNI) | Out-of-scope features, needless abstraction, unused configuration |
| F | Refactoring candidates | Core/Services/UI responsibility boundaries, state-management placement, consistency with the extension model (extensions.md) |
| G | Test health | All tests green (run them), no weakened assertions, coverage gaps for changed pure logic |
| H | Release hygiene | Version values; verification-record freshness (see criterion below); clean tree; CI definition; leftover TODO/placeholders; explicitly-marked provisional values (bundle ID etc.) |
| I | Accessibility regression | Labels, combined elements, and non-color state expression surviving UI churn |

### Freshness criterion (H)

The verification record is FRESH only if no commit after its recorded HEAD touches Swift sources or build settings (`project.yml`, `Info.plist`). Docs-only commits are acceptable. Stale record = High finding.

### Doc-drift severity guide (B)

- High: public-facing factual errors (README features/UI behavior)
- Medium: self-contradiction within or between spec documents
- Low: stale examples, mock diagrams, code comments not affecting behavior claims
- Ignore: pure phrasing/style differences

## Output format

1. Findings list (severity-ranked, numbered): `[Section / High|Medium|Low]` + file:line + what & why (concrete failure scenario or concrete benefit) + 1–2 sentence fix direction
   - High = fix before release / Medium = recommended / Low = next version is fine
2. Per-section summary (A–I, "none" where clean)
3. One-paragraph verdict (release readiness). List human-pending items and open H-decisions separately.
4. Distribution status when applicable: pushed commit, CI result, release tag/asset, Homebrew Cask version, and installed/running app version. Distinguish local build success from installed app update.

## Rules

- **Identify only. Modify or commit nothing.**
- Substantiate findings via grep/reading before writing them (mark unverified speculation as such).
- No re-litigating settled items (backlog ledger + [v1.x] markers) in any section.
