# Contributing to Room

Thanks for your interest! Room is a small project with strong opinions. Please read this before opening an issue or PR. Issues and PRs are welcome.

## Build & test

- Requires Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).
- `Room.xcodeproj` is a **generated file** — never edit or commit it. `project.yml` is the source of truth.

```bash
xcodegen generate
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' build
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test
```

Run the tests before submitting anything.

## Repository layout

| Path | Contents |
|------|----------|
| `Room/App` | Entry point (`RoomApp` / `MenuBarExtra`), `AppState`. |
| `Room/Core` | Pure, testable logic: formatting, aggregation, protection policy, cleanup rules. Foundation-only. **TDD — write tests first.** |
| `Room/Models` | Data models: `MemorySnapshot`, `StorageSnapshot`, `ProcessGroup`, `CleanupItem`, enums. |
| `Room/Services` | System API isolation layer (mach, sysctl, libproc, FileManager). Protocols + implementations. |
| `Room/UI` | Reusable components, screens (Popover, Processes, Make Room, Cleanup, Settings), icons. |
| `Room/Support` | Bridging header (libproc), constants. |
| `RoomTests/` | Unit tests. |

Views never talk to system APIs directly — always go through `Room/Services`.

## Hard rules

These are non-negotiable:

- **No network code, ever.** No analytics, no telemetry, no auto-update, no runtime dependencies.
- **No deletion without Review.** Room never removes files without an explicit user review step.
- **Never weaken the process protection policy** (`Room/Core/ProcessProtectionPolicy.swift`) or the cleanup safety guards (`Room/Core/CleanupTargetVerifier.swift`).
- **No runtime dependencies.** SwiftPM additions are disallowed.
- **Tests never touch real user data.** Use temporary fixture directories only — never write to or delete from `~/Library` or similar.

## Commits

- Conventional Commits: `feat:`, `fix:`, `test:`, `docs:`, `chore:`.
- Keep commits small and task-scoped.

## Where things are defined

- Product requirements: [`docs/requirements.md`](docs/requirements.md) — when in doubt, this is the source of truth.
- How to add a new metric or extension: [`docs/extensions.md`](docs/extensions.md).