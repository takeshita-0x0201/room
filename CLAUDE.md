# Room — Guide for Claude Code

Common rules are in @AGENTS.md (required reading). Build & test, repository structure, coding conventions, prohibitions, Git conventions, and Definition of Done are all defined in AGENTS.md. This file only covers the operating conventions specific to Claude Code.

## Agent operating structure (specific to this repository)

- The main session (parent) is **PM-only**. It only makes decisions, decomposes tasks, dispatches work, and reviews deliverables — it never implements, verifies, or runs tests itself.
- Implementation is delegated via the Agent tool to subagents with an explicit `model` (default `sonnet`; `opus` for hard spots involving system APIs, `haiku` for documentation).
- Task-by-task model assignment is decided by the PM at dispatch time (default `sonnet`, `opus` for system-API-heavy work, `haiku` for docs).

## Escalation

When quality is insufficient, respond in the following order.

1. First diagnose the cause. If ambiguous spec or insufficient context is the cause, keep the same model, improve the dispatch prompt, and retry (prefer this).
2. Only when the model's capability is judged insufficient, switch one step up to a higher model and retry (`haiku` → `sonnet` → `opus` → `fork`).
3. Escalation is limited to once per task. When re-running, always attach the failed diff, review comments, and unmet criteria (no re-runs from a blank slate).

## Items requiring human confirmation (PM must not decide unilaterally)

- Developer ID signing presence and policy
- Bundle ID finalization
- Final license approval
- Decision to make the GitHub repository public / perform a Release

## Manual verification notes

Room is a menu bar resident app. Builds and tests via `xcodebuild` can be automated, but verifying actual UI behavior (menu bar display, Popover open/close, actual file deletion, etc.) should be delegated to human visual checks. Instruct that any manual tests involving real deletions must use throwaway data.
