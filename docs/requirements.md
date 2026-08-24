# Room Requirements Specification v1.1

> **Room — See what's full. Make room.**
> A lightweight OSS app that shows RAM and SSD status at a glance in the macOS menu bar and safely frees up space only when needed.

This document is a revision that scrutinizes and elaborates the v1.0 Final to an implementable level.
All changes from v1.0 are marked with the **[v1.1 decision]** marker. The design philosophy and UI policy follow v1.0.

---

## 0. Review Summary (Reasons for v1.0 → v1.1 Changes)

v1.0 is clear in both philosophy and UI, but the following categories of undefined items remained before implementation could proceed.

| # | Issue | Resolution in v1.1 |
|---|------|--------------|
| 1 | App Sandbox handling undefined. Process enumeration, terminating other apps, and cache deletion are impossible under Sandbox | Decided **non-Sandbox**. Mac App Store distribution not possible → GitHub Releases distribution (§4) |
| 2 | TCC (macOS privacy protection) permission model undefined. `~/.Trash` requires Full Disk Access; Safari cache is TCC-protected | New permission model section (§5). Trash is opt-in with FDA; Safari is out of scope |
| 3 | Minimum supported macOS version undefined | Decided **macOS 14.0 (Sonoma) or later** (§4) |
| 4 | RAM usage formula undefined (macOS actively uses free RAM for cache, so free/total is inappropriate) | Defined Activity Monitor-compliant formula (§6.1) |
| 5 | SSD free space calculation method undefined (handling of APFS purgeable space) | Decided on Finder-matching `volumeAvailableCapacityForImportantUsage` (§6.2) |
| 6 | Process display aggregation unit undefined. Chrome etc. splits into many Helper processes; naive enumeration diverges from the spec's intent ("Chrome 3.2 GB") | Defined aggregation by .app bundle (§6.3) |
| 7 | Quit implementation path differs between GUI apps and non-GUI processes (node, etc.) — undefined | Defined two paths (`NSRunningApplication` / signal) (§14) |
| 8 | UI for the fact that Quit is a "request" and not guaranteed (can be blocked by unsaved-changes dialogs) undefined | Defined follow-up UI after timeout (§14.3) |
| 9 | Protection process criteria abstract | Elaborated the judgment rules (§15) |
| 10 | Cleanup double-counting risk (Yarn/Homebrew/CocoaPods caches live under `~/Library/Caches` and qualify for both the Caches and Developer categories) | Defined mutual-exclusion rules between categories (§17.4) |
| 11 | Deleting a running browser's cache risks data corruption | Defined rule to skip caches of running apps (§17.5) |
| 12 | Docker cache deletion depends on the external docker CLI + daemon running state | **Deferred to v0.2** (§20) |
| 13 | Review category (large Downloads files, duplicate detection) not in the §35 MVP list; duplicate detection is high-cost | **Deferred to v0.2** (§20) |
| 14 | Deletion method undefined (moving to the Trash doesn't increase free space) | Decided **permanent deletion** with mandatory Review confirmation (§17.6) |
| 15 | "Old Logs" threshold undefined | Decided last modified more than 7 days (§17.3) |

Minor decisions (consolidated in the §21 decision list): UI language English / monospaced digits / icon only when both Show Memory and Show Storage are OFF / RAM in base 1024, SSD in base 1000 / no auto-update mechanism, etc.

**Conclusion: v1.0's philosophy, UI, and scope are implementable. This v1.1 document, with the above elaborations, is the implementation baseline.**

---

## 1. Product Overview

**Room** is a lightweight open-source application that shows **RAM and SSD status at a glance in the macOS menu bar and safely frees up space only when needed**.

Room does not aim to be a feature-rich system monitor or all-in-one cleaner. It presents what the user wants to know with a minimal UI.

- How much RAM is being used now / whether it is actually running low
- How much of the SSD is used / how much free space there is
- What is pressuring the RAM
- How much space can be safely freed

## 2. Design Principles

1. **Glanceable** — see RAM / SSD status at a glance from the menu bar
2. **Simple** — keep information, actions, settings, and screen navigation to the necessary minimum
3. **Make Room** — Memory: "Pressure diagnosis → terminate unneeded high-memory processes"; Storage: "detect regenerable data → delete with user confirmation"
4. **Extensible** — keep the core small; everything beyond RAM / SSD becomes future Modules / Extensions

Room is not a RAM cleaner. It distinguishes "using a lot of RAM" from "actually running low on RAM" and treats Memory Pressure as the primary metric.

## 3. Product Boundaries

```text
Room Core                     Extensions (future)
├── Memory Monitor            ├── CPU / GPU / Battery
├── Storage Monitor           ├── Network / Docker
├── Process Monitor           ├── Temperature
└── Make Room                 └── Community Modules
    ├── Memory
    └── Storage
```

In v0.1, no Plugin Runtime is built. Only the internal structure (Service protocol separation) makes it easy to add modules later.

## 4. Target Environment & Distribution **[v1.1 decision]**

| Item | Decision | Reason |
|------|------|------|
| Minimum OS | **macOS 14.0 (Sonoma)** | SwiftUI `MenuBarExtra` popover open/close detection, `@Observable`, and the `openSettings` environment value require 14+. Also covers Intel Macs supported by Sonoma (most models from 2018 onward) |
| Architecture | Universal Binary (arm64 + x86_64) | Apple Silicon first; Intel also supportable with the same code |
| Language / UI | Swift 5.9+ / SwiftUI (AppKit only where necessary) | As specified |
| App Sandbox | **Disabled** | Process enumeration (libproc), terminating other apps, and deleting `~/Library/Caches` are impossible under Sandbox |
| Distribution | GitHub Releases (.zip / .dmg). Mac App Store **not possible** (non-Sandbox) | Consistent with OSS policy |
| Signing | Developer ID + Notarization recommended. **Whether/how to obtain a signing ID is a user (human) confirmation item** | Buildable as OSS even unsigned (Gatekeeper warning documented in README) |
| Dock | No icon (`LSUIElement = true`), menu bar resident | As specified |
| Network | Zero communication. No Analytics / Telemetry / auto-update. Updates are manual via GitHub Releases | Privacy principle (§19) |

## 5. Permission Model (TCC) **[v1.1 new]**

The areas Room handles and macOS permission requirements:

| Area | Permission | Room's handling |
|------|------|------------|
| RAM / SSD stats, process enumeration (own user) | Not required | Always available |
| Quit / Force Quit of other apps (owned by the current user) | Not required (non-Sandbox) | Always available |
| `~/Library/Caches`, `~/Library/Logs`, `$TMPDIR`, `~/.npm`, etc. | Not required | Always available |
| `~/.Trash` (size query & deletion) | **Full Disk Access required** | When FDA is not granted, the Trash row shows "size unknown" with a link to System Settings. Size display and deletion only when granted |
| Safari cache / data | TCC-protected (partially inaccessible even with FDA) | **Out of scope** (target browsers are non-TCC-protected areas only, e.g., Chrome / Firefox) |
| Desktop / Documents / Downloads | Per-folder consent prompt | Not scanned in v0.1 (Review category is v0.2) |

Principle: **Room never asks for permissions preemptively**. FDA is only suggested when the user tries to use the Trash feature.

## 6. Metric Definitions **[v1.1 new]**

### 6.1 Memory

| Metric | Definition |
|------|------|
| Total RAM | `ProcessInfo.processInfo.physicalMemory` |
| RAM used | `(max(internal − purgeable, 0) + wired + compressor) × pageSize` (`host_statistics64(HOST_VM_INFO64)`, matching Activity Monitor's "Memory Used". Clamping happens at the App Memory = internal − purgeable step so wired / compressor are never lost) |
| RAM usage | `used / total` |
| RAM free | `total - used` |
| Memory Pressure | Initial value: sysctl `kern.memorystatus_vm_pressure_level` (1=Normal, 2=Warning, 4=Critical). Change detection: `DispatchSource.makeMemoryPressureSource` (event-driven, no polling). **Failed or unknown reads are treated as Unavailable, distinct from Normal** (to avoid a false "No action needed") |
| Swap | sysctl `vm.swapusage` (`xsw_usage.xsu_used`) |
| Display base | **Base 1024** (`ByteCountFormatter.CountStyle.memory`) so 24 GB RAM displays as "24 GB" |

### 6.2 Storage

| Metric | Definition |
|------|------|
| Target | Boot disk (`/`) only. External / multiple volumes: future support |
| Total capacity | `volumeTotalCapacityKey` |
| Free space | **`volumeAvailableCapacityForImportantUsageKey`** (includes APFS purgeable; the same value Finder uses. Note: Finder's display can temporarily diverge due to caching) |
| Used | `total - free` |
| Usage | `used / total` |
| Display base | **Base 1000** (`ByteCountFormatter.CountStyle.file`, matching Finder) |

### 6.3 Process Aggregation Unit **[v1.1 decision]**

- When a process's executable path contains an `.app` bundle, **aggregate all processes of the same bundle (including Helpers) into one group** and display by app name (e.g., Chrome main process + all Helpers = "Chrome 3.2 GB")
- Processes not belonging to a bundle (`node`, `docker`, etc.) are shown individually
- RAM usage is the group sum of `proc_pid_rusage`'s `ri_phys_footprint` (the same metric as Activity Monitor's "Memory" column)
- Only **processes owned by the current user** are enumerated (other users' / root processes' footprints cannot be read, and they are not Quit targets either)

## 7. Overall UI Policy

- No dashboards / no card layouts / no pie charts or unnecessary charts
- No always-on animations / restrained use of color / no deep hierarchies (max 2 levels)
- Don't over-add settings / stay unobtrusive in normal use
- UI language is **English** (v0.1). No centralized string-management layer in v0.1 (YAGNI; introduce it when localization starts) **[v1.1 decision]**
- **`docs/design-system.md` is authoritative for UI design (icon set, colors, component styles, number formatting)** (structured from the user-provided design sheet, 2026-08-20). Always-on colors such as usage bars and Pressure state colors (Normal=blue) follow it, revising v1.1's "achromatic in normal state" principle **[v1.2 decision]**

## 8. Room Icon

"Frameless spatial volume" — a view into a cube from above at an angle, with only three faces rendered as wireframe: the bottom, the back-left, and the back-right. There is no front face and no top face.

Requirements: wireframe / faces unfilled / monochrome / geometric / vector-based / macOS Template Image support (auto Light / Dark) / recognizable at 16–18px / line weight not too thin.

**[v1.1 decision]** Memory / Storage icons use SF Symbols (`memorychip` / `internaldrive`) in v0.1. Only the Room icon is custom-made.

## 9. Menu Bar Display

Default:

```text
[Memory Icon]72 [Storage Icon]68
```

The Room icon is not always shown in the menu bar (v0.1 on-device feedback). **[v1.2 revision]**

- No text such as `RAM`, `SSD`, `%`, or separator dots is shown — icon + number only
- Display order is fixed as Memory → Storage
- **[v1.1 decision]** Numbers are rendered in monospaced digits to prevent width jitter on updates
- **[v1.1 decision]** When both Show Memory and Show Storage are OFF, only the Room icon is shown

### Display Modes (toggled in Settings, reflected in the menu bar immediately)

| Mode | Example | Content |
|--------|--------|------|
| Percentage (default) | `▦72 ▱68` | Usage |
| Free | `▦5.6G ▱171G` | Free space |
| Used | `▦18.4G ▱341G` | Used |

Compact notation: below 100G, one decimal place, `.0` omitted (`5.6G`, `18.4G`, `24G`); 100G and above, integer (`171G`, `341G`) plus one-letter unit. Follows the v1.0 §8 example (`▦18.4G ▱341G`). **[v1.1 decision]**

## 10. Main Popover

Shown by clicking the Room icon. Width 280–320px, variable height, max 2 levels of hierarchy.

```text
╭──────────────────────────────╮
│ ◇ Room                       │
│                              │
│ MEMORY                  72%  │
│ 18.4 / 24 GB                 │
│ Free      5.6 GB             │
│ Pressure  Normal             │
│ Swap      768 MB             │
│                              │
│ STORAGE                 68%  │
│ 341 / 512 GB                 │
│ Free      171 GB             │
│                              │
│ TOP PROCESSES                │
│ Chrome               3.2 GB  │
│ Cursor               2.4 GB  │
│ node                 1.1 GB  │
│                              │
│ ◇  Make Room                 │
│ ◎  Processes             ›   │
│ ⚙  Settings                  │
╰──────────────────────────────╯
```

*Historical v1.0 mock — see the [v1.2] bullets below and docs/design-system.md for the current layout.*

- Section headings (Memory / Storage / Top Processes) carry icons, **Title Case, not bold, body size** (text and icon the same size) (reflecting v0.1 on-device feedback) **[v1.2 revision]**
- The Room icon and the service name "Room" in the popover header are shown slightly larger **[v1.2 revision]**
- Make Room / Processes are push navigations within the popover (1 level)
- Settings is a separate window (macOS standard)
- Top Processes is the top 3 groups by RAM usage. Only the app / process name + RAM usage is shown (no CPU, etc.)

## 11. Memory Monitor

Displayed items: RAM usage / used / total / free / Memory Pressure / swap used.

Room does **not judge abnormality by RAM usage alone**. Memory Pressure (Normal / Warning / Critical) is the primary metric; `RAM 90% / Pressure Normal` produces no warning.

## 12. Storage Monitor

Displayed items: SSD usage / used / total / free. Computed per §6.2, showing the capacity actually available to the user (matching Finder).

## 13. Processes Screen

Reached via `Processes ›` in the popover, it shows a list in descending order of RAM usage (aggregated per §6.3). Each row offers Quit / Force Quit.

## 14. Quit / Force Quit **[v1.1 elaborated]**

### 14.1 Quit (Normal Termination)

- .app group → `NSRunningApplication.terminate()` (macOS standard graceful termination flow; respects the app's unsaved-changes dialog)
- Non-GUI processes → `SIGTERM`
- Never prioritize operations that would lose unsaved user data

### 14.2 Force Quit (Forced Termination)

- .app group → `forceTerminate()`, non-GUI → `SIGKILL`
- A confirmation dialog always precedes execution:

```text
Force Quit Chrome?
Unsaved changes may be lost.
[Cancel] [Force Quit]
```

### 14.3 When Quit Is Blocked **[v1.1 new]**

`terminate()` is a "termination request"; the app will not quit if it doesn't respond (e.g., showing an unsaved-changes dialog). If the process is still alive about 5 seconds after the Quit request, the row shows `Still running` and a `Force Quit` option. Room never Force Quits automatically.

### 14.4 Execution Safety Checks **[v1.1 new]**

- QuitService re-evaluates the protection policy (§15) at the service layer too (defense in depth, not relying only on UI disabling)
- To guard against PID reuse, right before the operation confirm the target PID's executable path (.app group: bundle path) still matches what was recorded. If it doesn't match or can't be verified, do nothing
- The liveness check (Still running determination) also goes through the identity check first

## 15. Process Protection Rules **[v1.1 elaborated]**

Groups matching any of the following cannot be Quit / Force Quit (operations are disabled in the UI too):

1. Room itself
2. PID 0 / 1 (kernel_task / launchd)
3. Groups containing processes owned by anyone other than the current user
4. On the denylist: `WindowServer`, `loginwindow`, `Dock`, `SystemUIServer`, `ControlCenter`, `NotificationCenter`, `Spotlight`, `coreaudiod`, `mds`, `mds_stores`, `logd`, `launchservicesd`, `distnoted`, `cfprefsd`
5. Executable path under `/System/Library/CoreServices` (exception: Finder may be Quit; harmless because macOS auto-relaunches it)

Protection judgment is implemented as pure functions and guaranteed by unit tests.

## 16. Make Room (Hub)

```text
MAKE ROOM

Memory
Pressure Normal
No action needed          ›

Storage
15.1 GB cleanable         ›
```

Memory and Storage use separate logic.

## 17. Make Room — Memory

### 17.1 Philosophy

Don't make it a RAM cleaner. The following are **not goals**: forcibly lowering usage / unconditionally purging inactive cache / processes that only inflate the free RAM figure / a "Freed" message with no substance.

Room operates as a **Memory Pressure Manager**:

1. Diagnose Memory Pressure
2. Check swap usage
3. Show high-memory processes
4. User selects the targets
5. Execute a normal Quit
6. Force Quit only when necessary

**Room never terminates apps on its own.**

### 17.2 When Pressure Is Normal

```text
MEMORY          72%
Pressure        Normal
No action needed
```

Even at high usage, if Pressure is Normal, show `No action needed` and no selection list (manual Quit is always available from the Processes screen).

When Pressure cannot be read (Unavailable), do **not** show `No action needed`. Show `Pressure unavailable` and hold the judgment. **[v1.1 additional decision]**

### 17.3 When Pressure Is Warning / Critical

Show the top high-memory processes; select with checkboxes → `Quit Selected` performs a normal Quit.

```text
Select apps to quit
□ Chrome    6.2 GB
□ Docker    4.1 GB
□ Cursor    3.8 GB

Potential recovery   14.1 GB
[Cancel] [Quit Selected]
```

### 17.4 Potential Recovery

Show the sum of the selected processes' current footprints as an estimate. **Do not present it as a guarantee that this capacity will become fully free** (the wording is "Potential recovery").

## 18. Make Room — Storage (Cleanup)

### 18.1 Principles

**Never delete important data without confirmation.** A Review always comes before deletion, with per-item ON/OFF.

### 18.2 Categories and Targets (v0.1) **[v1.1 elaborated]**

| Level | Item | Path | Conditions |
|--------|------|------|------|
| Safe | Application Cache | `~/Library/Caches/*` | Exclude `com.apple.*`. Exclude caches of running apps. Exclude paths claimed by the Developer / Browser categories |
| Safe | Browser Cache | Chrome: `~/Library/Caches/Google/Chrome`, Firefox: `~/Library/Caches/Firefox` (actually under `Profiles/<profile>/cache2`) | Skipped while the target browser is running (§18.4). Safari is out of scope (TCC) |
| Safe | Temporary Files | `$TMPDIR` (current user) | Last modified more than 3 days ago |
| Safe | Logs | `~/Library/Logs` | Last modified more than **7 days** ago |
| Safe | Trash | `~/.Trash` | **Only when FDA granted** (§5). Otherwise the row shows "Grant Full Disk Access to include Trash" |
| Developer | Xcode DerivedData | `~/Library/Developer/Xcode/DerivedData` | |
| Developer | Simulator Cache | `~/Library/Developer/CoreSimulator/Caches` | |
| Developer | npm / pnpm / yarn Cache | `~/.npm/_cacache` / pnpm store (environment-dependent: whichever of `~/Library/pnpm/store`, `~/.local/share/pnpm/store`, `~/.pnpm-store` exist) / `~/Library/Caches/Yarn` | Only show those that exist |
| Developer | Homebrew Cache | `~/Library/Caches/Homebrew` | |
| Developer | CocoaPods Cache | `~/Library/Caches/CocoaPods` | |
| Developer | Gradle Cache | `~/.gradle/caches` | |

### 18.3 Category Exclusion Rules **[v1.1 new]**

Yarn / Homebrew / CocoaPods caches live under `~/Library/Caches`. **Paths claimed by specific rules are excluded from Application Cache (the generic scan)** to prevent double-counting and double-deletion. This exclusion is guaranteed by unit tests.

In addition, the generic scan only targets **directories in reverse-DNS format (names containing two or more dots)**. Vendor-name directories like `Google` or `JetBrains` cannot be matched against running apps (bundle IDs), so the §18.4 protection cannot be applied; anything without an explicit rule is excluded. **[v1.1 additional decision]**

### 18.4 Protection of Running Apps **[v1.1 new]**

When a target app (browser, Xcode, etc.) is running, its cache items are non-selectable, with a reason shown such as `Quit Chrome to clean` — deleting a running app's cache can cause data corruption.

This "blocked display" applies only to explicit rules (Chrome / Firefox / Xcode, etc.). **Running apps' entries inside the generic Application Cache scan are excluded from scanning rather than shown as rows** (the safe side; they become eligible on the next scan after the app quits). Per-app row display is considered for v0.2. **[v1.1 additional decision]**

### 18.5 Deletion Method **[v1.1 decision]**

Items confirmed in Review are **permanently deleted** (`FileManager.removeItem`). Moving to the Trash would not increase the SSD's actual free space and would not serve Make Room's purpose. All targets are limited to regenerable data, and the mandatory Review is the safety net. The directory itself is kept; only its contents are deleted.

**Re-verification at deletion time (TOCTOU countermeasure) [v1.1 additional decision]**:

1. Record each target's inode / device number at scan time and **re-verify the match immediately before deletion**. Skip on mismatch (replaced or already deleted)
2. Symbolic links are never targets (excluded at scan time and re-checked at deletion time)
3. Re-verify immediately before deletion that the target is under an allowed root (the rule's roots)
4. The §18.4 running-app check is **re-run immediately before deletion** (in case the target app launched after scanning)
5. Verify that the target's symlink-resolved real path is also under an allowed root (to prevent escaping the area via intermediate symlinks) **[v1.1 additional decision]**

**Known limitation (v0.1)**: inode re-verification and the actual deletion are path-based operations, so there is no full atomicity (fd-based `openat`/`unlinkat` deletion). A same-user malicious process swapping a target within the millisecond-scale window between verification and deletion cannot be prevented, but same-user malicious code could delete files directly without Room, so this is outside v0.1's threat model (accidental modifications or swaps are covered by inode verification and real-path verification). fd-based deletion is recorded in the backlog as a future item.

### 18.6 Scan and UI

```text
STORAGE
341 / 512 GB
Free            171 GB

CLEANABLE
Caches           4.8 GB
Developer        8.2 GB
Logs           420 MB
Trash            1.7 GB
Total           15.1 GB

[Review]
```

Note: v1.0's two buttons `[Review] [Make Room]` were redundant (both navigated to the Review screen), so they are consolidated into a single **blue `Review` button** (design-system §8). **[v1.2 revision]**

Review screen (each item can be toggled ON/OFF):

```text
✓ Application Cache   2.8 GB
✓ Browser Cache       2.0 GB
✓ Developer Cache     8.2 GB
✓ Logs               420 MB
✓ Trash               1.7 GB
Total                15.1 GB
[Cancel]  [Clean]
```

- Scanning runs only when Make Room (Storage) is opened (in the background, cancellable)
- The CLEANABLE Total sums **only items that are ready to delete now**. Items blocked by running apps are shown as "+X GB after quitting apps"; Trash without FDA is shown separately as a hint row (so the apparent Total matches what can actually be cleaned) **[v1.1 additional decision]**
- After deletion completes, show the **total size of the files actually deleted** (fact-based; because APFS free-space updates can lag, the free-space delta is not shown as the result) **[v1.1 revision]**
- Deletion errors (files in use, etc.) are skipped per item and shown in the results as `Skipped (in use)` **[v1.1 new]**

## 19. Settings

```text
GENERAL
  Appearance             System / Light / Dark
  Launch at Login        ON        ← SMAppService.mainApp (macOS 13+ standard API)
MENU BAR
  Show Memory            ON
  Show Storage           ON
  Display                ● Percentage ○ Free ○ Used   ← One-line preview of the selected mode (real icons + fixed sample values; no measured values) **[v1.1 revision]**
  Refresh Interval       ● 5 sec ○ 10 sec ○ 30 sec
```

- Appearance / Display / Show settings are reflected in the app and menu bar immediately
- System appearance follows the current macOS appearance; Light and Dark override it for Room only
- Settings are stored in `UserDefaults` (`@AppStorage`)

### Refresh Policy

- **Lightweight reads** (RAM stats, SSD capacity): refreshed periodically per Refresh Interval
- **Memory Pressure**: event-driven (DispatchSource), no polling
- **Process list**: updated when the popover **opens** and **after a Quit operation**. No periodic re-refresh while displayed (rebuilding rows would interfere with in-progress clicks; UX fix from v0.1 on-device feedback) **[v1.1 revision]**
- **Storage Cleanup Scan**: only when Make Room (Storage) is opened
- While the popover is closed, only the lightweight reads needed for the menu bar display run

## 20. Out of Scope (v0.1) **[v1.1 clarified]**

| Item | Reason | Plan |
|------|------|------|
| Docker cache deletion | Depends on the external docker CLI and daemon state | v0.2 |
| Review category (large Downloads files / DMG / ZIP / old installers / duplicate detection) | Not in the v1.0 §35 MVP list. Duplicate detection is high-cost. Downloads requires TCC consent | v0.2 (the discover-and-present-only principle is kept) |
| Safari cache | Inaccessible due to TCC protection | No plan to support |
| External SSDs / multiple volumes | Future support as specified | v0.x |
| CPU / GPU / Battery / Network / Temperature | Extensions | Future |
| Plugin Runtime | Not needed as specified | Future |
| Auto-update | Zero-network principle | Not considered (alternatives like Homebrew cask) |

## 21. Decision Log (PM decisions) **[v1.1]**

| # | Decision | Basis |
|---|------|------|
| D1 | Minimum OS: macOS 14.0 | §4 |
| D2 | Non-Sandbox / GitHub Releases distribution | §4 |
| D3 | RAM used = Activity Monitor-compliant formula | §6.1 |
| D4 | SSD free = importantUsage key (matches Finder) | §6.2 |
| D5 | Processes aggregated per .app bundle | §6.3 |
| D6 | RAM in base 1024 / SSD in base 1000 | §6.1, §6.2 |
| D7 | Quit via two paths (NSRunningApplication / SIGTERM) | §14 |
| D8 | Offer Force Quit after 5 seconds when Quit is blocked | §14.3 |
| D9 | Protection rules (denylist + ownership + /System/Library/CoreServices) | §15 |
| D10 | Trash requires FDA opt-in | §5, §18.2 |
| D11 | Cleanup uses permanent deletion (Review required) | §18.5 |
| D12 | Skip caches of running apps | §18.4 |
| D13 | Path exclusion between categories | §18.3 |
| D14 | Logs older than 7 days / Temp older than 3 days | §18.2 |
| D15 | Docker cache and Review category deferred to v0.2 | §20 |
| D16 | English UI, monospaced digits, SF Symbols (Memory/Storage) | §7–9 |
| D17 | Build via XcodeGen (`project.yml` authoritative; `.xcodeproj` is generated) | See implementation plan. For diff reviewability |
| D18 | License: MIT proposed | OSS standard. **Final approval is a human decision** |
| D19 | Re-verification immediately before cleanup deletion (inode/device match, symlink rejection, under allowed roots, running-app re-check) | §18.5 |
| D20 | Generic Caches scan targets reverse-DNS name directories only | §18.3 |
| D21 | Unreadable Memory Pressure is Unavailable, distinct from Normal | §6.1, §17.2 |
| D22 | Cleanable Total sums only ready items; deletion results show total deleted size | §18.6 |
| D23 | Quit / Force Quit also do protection checks + process identity verification at the service layer | §14.4 |

### Human (User) Confirmation Items

| Item | Details |
|------|------|
| H1 | Apple Developer Program / Developer ID signing presence and policy |
| H2 | Bundle ID finalization (tentative: `dev.takeshita.Room`; changeable in `project.yml`) |
| H3 | Final license approval (MIT proposed) |
| H4 | Decision to make the GitHub repository public and perform the first Release |
| H5 | Development environment setup: **install Xcode 16 or later** and run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` (the current environment only has Command Line Tools and cannot run `xcodebuild` — a blocker for starting implementation) |

## 22. Non-Functional Requirements

### Performance

```text
Idle CPU   ≈ 0% (popover hidden: one timer + event-driven only)
RAM        Target: within a few tens of MB
Network    0
```

### Privacy

Analytics / Telemetry / Usage Tracking / accounts / unnecessary network communication / user-data transmission — all prohibited. Fully local operation.

### Accessibility

- VoiceOver labels on all UI elements
- Keyboard navigation
- Light / Dark Mode support
- Sufficient contrast
- State expression beyond color (Pressure always pairs the text "Normal/Warning/Critical". State colors: Normal=blue / Warning=yellow / Critical=red. Always-on colors such as usage bars follow `design-system.md` §3) **[v1.2 revision]**

### OSS Policy

Small codebase / minimal external dependencies (zero runtime dependencies; XcodeGen is the only dev tool) / Swift standard APIs preferred / CONTRIBUTING.md / document how to add Extensions / no telemetry.

README opening:

```markdown
# Room

**See what's full. Make room.**

A tiny macOS menu bar app for memory and storage.
```

## 23. MVP v0.1 Acceptance Criteria

### Feature Checklist (per v1.0 §35 + v1.1 adjustments)

- [ ] Menu bar resident, no Dock icon
- [ ] Room icon (custom) / Memory & Storage icons (SF Symbols)
- [ ] `▦72 ▱68` equivalent display (Percentage / Free / Used, instant switching)
- [ ] RAM usage, used, free, total, Memory Pressure, swap
- [ ] SSD usage, used, free, total (matches Finder)
- [ ] Top 3 processes (grouped per app)
- [ ] Processes list (RAM descending) + Quit / Force Quit + protection rules
- [ ] Memory Make Room (`No action needed` at Normal / selective Quit + Potential recovery at Warning / Critical)
- [ ] Storage Make Room (scan → Cleanable display → Review → selective deletion → actual-result display)
- [ ] Settings (Appearance / Launch at Login / Show toggles / Display mode + preview / Refresh Interval)
- [x] Light / Dark Mode
- [ ] VoiceOver labels and keyboard operation

### Memory Make Room Completion Criteria (v1.0 §36)

- At Normal: can display `Pressure Normal` + `No action needed`
- At Warning / Critical: can identify high-memory processes, display them, and Quit them selectively. Force Quit possible only when needed

### Storage Make Room Completion Criteria (v1.0 §37)

- Can detect safely deletable candidates with per-category sizes
- Can Review before deletion and delete only the selected items

## 24. Architecture

```text
Room/
├── App/            RoomApp (MenuBarExtra), AppState, RefreshScheduler
├── Models/         MemorySnapshot, StorageSnapshot, ProcessGroup, CleanupItem, various enums
├── Services/       MemoryService, StorageService, ProcessService, QuitService, CleanupService
│                   (all protocol + implementation; system APIs isolated here)
├── Core/           Pure logic: aggregation, protection policy, cleanup rules, formatters
├── UI/
│   ├── Components/ Reusable views (SectionHeader, StatRow, …)
│   ├── Screens/    PopoverRoot, Processes, MakeRoom, Cleanup, Settings
│   └── Icons/      RoomIcon (template image)
└── Support/        Bridging Header (libproc), constants
```

- **Never write system acquisition code directly inside Views** (via Services only)
- Core is pure logic depending only on Foundation and is the primary target of unit tests
- Keep a structure where adding an Extension is just adding a "Service protocol + Screen"

---

## 25. Final Definition

Room is not a RAM cleaner. Nor is it a comprehensive system monitor.

> **A small tool to see at a glance how much Room is left on your Mac, and to safely make room only when you truly need it.**

- Memory: **Diagnose pressure. Quit what you don't need.**
- Storage: **Find what can safely go. Make room.**
- Product overall: **Room — See what's full. Make room.**
