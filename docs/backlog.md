# Backlog — Deferred Items Ledger

Settled deferrals. The release audit (`/release-audit`) must NOT re-report items listed here.
Each entry records what was deferred, why, and where it was decided.

## Deferred from v0.1 (target: v0.2+)

| # | Item | Why deferred | Decided |
|---|---|---|---|
| B1 | fd-based atomic deletion (`openat`/`unlinkat`, `O_NOFOLLOW`) for the cleanup path | Same-user malicious processes are outside the v0.1 threat model; inode + resolved-path verification covers accidental races | requirements §18.5 known-limitation note (gate #2) |
| B2 | Failure-injection tests for system-API service adapters (Memory/Storage/Process) | Requires injectable syscall layer; pure logic is unit-tested, adapters are integration-verified | Codex gate #1, P3 |
| B3 | Consolidate view-owned services/policies (`QuitService`, `CleanupService`, `ProcessProtectionPolicy`, `isCleaning` gate) into `AppState` or a coordinator, injected via environment | Working correctly today; restructuring is v0.2 groundwork for the extension model | Fable audit #4 (2026-08-20) |
| B4 | Custom Memory/Storage menu-bar glyphs unified with the Room icon language (replacing SF Symbols) | SF Symbols are acceptable for v0.1 | design-system §2 (phase D5) |
| B5 | Per-entry "Quit X to clean" rows for running apps inside the generic cache scan | Requires per-child cleanup items; v0.1 silently excludes running apps' dirs (safe side) | requirements §18.4 [v1.1] note |
| B6 | Memoize `MenuBarLabelRenderer.image` keyed by (memory, storage) strings | Recompose cost is already bounded by AppState equality gating | Fable release audit #8 (2026-08-20) |
| B7 | Placeholder/empty state for Top Processes while first enumeration is in flight | Cosmetic; visible only for a moment on first open | Fable audit #9 |
| B8 | Merge the parallel `ByteText.short`/`long` tier ladders into one formatter core | Partially addressed by `scaledValue`; remaining duplication is small | Fable audit #10 |
| B9 | Own the 5-second quit-recheck task in AppState (cancel on popover close, generation counter) | Harmless today: `refreshProcesses` is visibility-guarded | Codex gate #2 #7 / Fable audit #11 |
| B10 | Docker cache cleanup, Review category (large Downloads files, duplicates), multi-volume support, plugin runtime | Out of v0.1 scope by requirements | requirements §20 |

## Not planned

| Item | Why |
|---|---|
| Safari cache cleanup | TCC-protected; inaccessible even with Full Disk Access |
| Auto-update mechanism | Zero-network principle; distribution via GitHub Releases |
