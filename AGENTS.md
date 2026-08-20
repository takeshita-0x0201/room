# Room — Agent Guide

This document defines the common rules that every agent involved in Room development (Claude / Codex, etc., tool-agnostic) should read first.

## 1. Project Overview

**Room — See what's full. Make room.**

Room is a lightweight OSS app that lives in the macOS menu bar, lets you see **RAM / SSD status at a glance**, and lets you **clean up safely (Make Room)** only when needed.

Room is not a RAM cleaner. It distinguishes "using a lot of RAM" from "actually running low on RAM" and treats Memory Pressure as the primary metric.

Design principles:

1. **Glanceable** — see RAM / SSD status at a glance from the menu bar
2. **Simple** — keep information, actions, settings, and screen navigation to the necessary minimum
3. **Make Room** — Memory: "Pressure diagnosis → quit unneeded high-memory processes"; Storage: "detect regenerable data → delete with user confirmation"
4. **Extensible** — keep the core small; everything beyond RAM / SSD becomes future Modules / Extensions

## 2. Required Reading

Read the following before starting any implementation.

- `docs/requirements.md` — requirements specification v1.1. Includes metric definitions (§6), permission model (§5), process protection rules (§15), cleanup specification (§17–18), and more.
- `docs/superpowers/plans/2026-08-20-room-mvp.md` — implementation plan. Includes task decomposition and assigned model per task.

**When in doubt about a specification decision, `docs/requirements.md` is authoritative.**

## 3. Build & Test

Prerequisites:

- Xcode 16 or later
- `brew install xcodegen`

`.xcodeproj` is a generated artifact of XcodeGen and is **not committed** (`project.yml` is the source of truth).

```bash
xcodegen generate
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' build
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test
```

## 4. Repository Structure

| Path | Contents |
|------|------|
| `project.yml` | XcodeGen definition. Source of truth for the project configuration. |
| `Room/App` | Entry point (`RoomApp` / `MenuBarExtra`) and `AppState`. |
| `Room/Core` | Pure logic: formatters, aggregation, protection policy, cleanup rules. Depends only on Foundation; unit tests required. |
| `Room/Models` | Data models such as `MemorySnapshot` / `StorageSnapshot` / `ProcessGroup` / `CleanupItem`. |
| `Room/Services` | System API isolation layer (mach, sysctl, libproc, FileManager). Separated into protocol + implementation. |
| `Room/UI` | `Components` (reusable views) / `Screens` (Popover, Processes, MakeRoom, Cleanup, Settings) / `Icons`. |
| `Room/Support` | Bridging Header (libproc, etc.), constants. |
| `RoomTests/` | Unit tests. |

## 5. Coding Conventions

- Prefer Swift 5.9+ / SwiftUI (AppKit only where necessary).
- Zero runtime external dependencies. Adding SwiftPM dependencies is prohibited.
- Never write system acquisition code directly in Views. Always access via `Room/Services`.
- Implement `Room/Core` with TDD (test-first).
- UI strings are in English.
- All project content — documents, code comments, commit messages, UI strings — is written in English.
- Use monospaced digits for numeric display.
- RAM is displayed in base 1024, storage in base 1000 (see `docs/requirements.md` §6).

## 6. Absolute Prohibitions

- No network communication code (including Analytics / Telemetry / auto-update) may be added.
- No file deletion logic without user confirmation (Review flow required).
- The process protection rules (`docs/requirements.md` §15) may not be relaxed.
- App Sandbox must not be enabled (breaks process enumeration).
- Tests must not write to or delete real user data (`~/Library`, etc.). Always use a temporary fixture directory.

## 7. Git Conventions

- Follow Conventional Commits (`feat:` / `fix:` / `test:` / `docs:` / `chore:`).
- Make small commits per task.
- Append the following trailer at the end of commit messages.

  ```
  Co-Authored-By: Claude Fable 5 <noreply@anthropic.com>
  ```

- Commit directly to main during early development.
- Do not push until instructed by the user.

## 8. Definition of Done

A task is complete only when all of the following are satisfied.

- The task's tests are green (`xcodebuild test` passes).
- No new build warnings.
- No placeholders (TODO, stub implementations) left behind.
- The corresponding acceptance criteria in `docs/requirements.md` are satisfied.
