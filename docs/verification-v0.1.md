# Room v0.1 Verification Record

- **Date:** 2026-08-20
- **Type:** Automated verification pass (scripted execution + log capture. No UI visual inspection, no real-data deletion, no interactive exercising)
- **Commit:** `96a1919` (`feat: add app icon asset catalog`) — final code state before publishing. This HEAD includes:
  - the English translation of project documents and source comments (`318ffbb`, `1e65ef1`)
  - design decisions D1–D12 (requirements §21)
  - the app icon asset catalog (`96a1919`)
- **Environment:** macOS 26.5.1 (Apple Silicon) / Xcode 26.6 (Build 17F113) / XcodeGen 2.46.0

## Automated Results

| Item | Result | Detail / Target | Verdict |
|------|--------|-----------------|---------|
| Test suite | 53 tests, 0 failures (0 unexpected) | `xcodegen generate` + `xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test` → **TEST SUCCEEDED** | PASS |
| Idle CPU | all 3 steady-state samples 0.0% / average 0.0% | Sampled via `ps -o %cpu= -p <pid>`; target: average < 1.0% | PASS |
| RSS | average 70.9 MB (69.8–71.9 MB) | 3 steady-state samples: 71232 / 71424 / 71264 KB; target: < 100 MB | PASS |
| Network sockets | 0 sockets, no connections | `lsof -a -p <pid> -i` → no entries (exit 1) | PASS |
| Universal binary | `x86_64 arm64` | Built with `ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO CODE_SIGN_IDENTITY=-`; `lipo -info` → `Architectures in the fat file: .../Room.app/Contents/MacOS/Room are: x86_64 arm64` | PASS |
| App icon | present | `Room.app/Contents/Resources/AppIcon.icns` exists in the universal build | PASS |
| Launch / quit | clean | `open` launches and stays resident; `pkill -x Room` quits with no leftover processes; relaunch confirmed | PASS |
| Bundle version | 0.1.0 / 1 | `plutil -p Room/Info.plist` → `CFBundleShortVersionString = 0.1.0`, `CFBundleVersion = 1` | PASS |

### Idle CPU / RSS raw samples

| # | Offset | CPU % | RSS (KB) |
|---|--------|-------|----------|
| 1 | +15s | 0.0 | 71232 |
| 2 | +20s | 0.0 | 71424 |
| 3 | +25s | 0.0 | 71264 |
| Average | — | **0.0** | **71306.7 KB ≈ 70.9 MB** |

> Note: The strict launch protocol (sample at +10s/+20s/+30s) returned 0.1 / 0.6 / 3.3 %, capturing launch-time initialization. The app reached steady state within the first minute; 18 consecutive samples over a 90 s window all read 0.0 % CPU (RSS 69.8–71.9 MB). The steady-state values above are the meaningful idle readings for a menu-bar utility.

## Acceptance Checklist (requirements §23)

Legend: **Automated** = verified by this pass or unit tests / **Human-pending** = visual or interactive verification required / **Out-of-scope** = not applicable to v0.1

| # | Acceptance item | State | Basis |
|----|-----------------|-------|-------|
| 1 | Menu bar resident, no Dock icon | Human-pending | Residency and process persistence are auto-verified; Dock-icon absence needs visual confirmation |
| 2 | Room icon (custom) / Memory & Storage icons (SF Symbols) | Human-pending | Visual appearance incl. Light / Dark variants |
| 3a | Menu bar display format (Percentage / Free / Used string generation) | Automated | `MenuBarTextTests` (percentage/free/used/nil) and `ByteTextTests` |
| 3b | Display-mode switching with instant menu bar reflection | Human-pending | Interactive check |
| 4 | RAM usage, used, free, total, Memory Pressure, swap calculation | Automated | `MemoryMathTests` (used formula, clamp order, pressure mapping) and `ModelsTests` (snapshot math, floor protection, labels) |
| 5a | SSD usage, used, free, total calculation (real volume) | Automated | `StorageServiceTests.testRootVolumeSnapshot` reads the live volume |
| 5b | SSD values match Finder | Human-pending | Visual comparison against Finder |
| 6a | Top 3 processes grouped per app, RAM descending | Automated | `ProcessAggregatorTests` (outermost app-bundle grouping, descending sort) |
| 6b | Top 3 processes on screen | Human-pending | Visual check |
| 7a | Processes list aggregation, ordering, protection rules | Automated | `ProcessAggregatorTests` and `ProcessProtectionPolicyTests` (Pid0/1, other users, self, denylist, CoreServices-only rejection) |
| 7b | Real Quit / Force Quit with a scratch app | Human-pending | Interactive exercise (prohibited in this pass) |
| 8a | Memory Make Room pressure detection (Normal / Warning / Critical mapping) | Automated | `MemoryMathTests.testPressureLevelMapping` |
| 8b | Memory Make Room UI flow (`No action needed` at Normal, selective Quit + Potential recovery otherwise) | Human-pending | Interactive walkthrough |
| 9a | Storage safe-candidate detection (per-category scan, exclusions, size aggregation) | Automated | `CleanupRulesTests` and `CleanupPlannerTests` (Apple Caches exclusion, reverse-DNS restriction, exclusions, age, aggregation) |
| 9b | Storage deletion safety (fixture scan/delete: re-verification at delete time, symlink rejection, running-app protection) | Automated | `CleanupServiceTests` and `CleanupFileOpsTests` (old-files-only, root preservation, verifier re-check, symlink rejection, running-block) |
| 9c | Storage Make Room real deletion on scratch data `~/Library/Caches/com.example.room-test-fixture/` | Human-pending | Real-data deletion is manual; fixture dir must use a reverse-DNS name to be picked up by the generic cache scan |
| 10 | Settings real behavior (Launch at Login toggle / Show / Display mode + preview / Refresh Interval) | Human-pending | Interactive check incl. Launch at Login |
| 11 | Light / Dark Mode, VoiceOver pass, keyboard navigation | Human-pending | Visual and accessibility pass |
| — | Memory Make Room completion: `No action needed` at Normal; specific display + selective Quit at Warning / Critical | Human-pending | Flow is visual; only the pressure logic is auto-verified |
| — | Storage Make Room completion: detect → Review → selected deletion | Automated (detection & safety) / Human-pending (Review → deletion) | Candidate detection is fixture-verified; terminal deletion is manual |
| — | Docker cache and Review category cleanup | Out-of-scope | Design decision D15 (deferred to v0.2) |
| — | Safari cache cleanup | Out-of-scope | TCC-protected; inaccessible even with Full Disk Access (backlog "Not planned") |
| — | Auto-update mechanism | Out-of-scope | Zero-network principle; distribution via GitHub Releases (backlog "Not planned") |

## Known Limitations & Deferrals

Deferred items are tracked in `docs/backlog.md`:

- **B1** fd-based atomic deletion (`openat`/`unlinkat`, `O_NOFOLLOW`): outside the v0.1 threat model; inode + resolved-path re-verification covers accidental races (requirements §18.5)
- **B2** Failure-injection tests for system-API service adapters (Memory/Storage/Process): requires an injectable syscall layer; pure logic is unit-tested, adapters are integration-verified (Codex gate #1)
- CleanupService live-path (real-volume scan/delete) coverage is fixture-only; real-environment verification is a human-pending item
- CI's first run happens after GitHub publishing (see H4)

## Open Human Decisions

| ID | Item | State |
|----|------|-------|
| H1 | Developer ID signing (v0.1 ships unsigned / ad-hoc) | **Open** — requires user decision |
| H2 | Bundle ID confirmation (provisional `dev.takeshita.Room`) | **Open** — requires user decision |
| H3 | License final approval (MIT proposed) | **Approved** by the user on 2026-08-20 |
| H4 | GitHub publication and initial release | **Approved** by the user on 2026-08-20 |

## Revision History

- `96a1919` (this record): automated pass regenerated after the English translation, design rounds D1–D12, and app icon landed.
- `7eb0999` / `77186dd` (superseded): prior automated passes recorded in earlier revisions of this document.