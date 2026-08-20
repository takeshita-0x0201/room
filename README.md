# Room

**See what's full. Make room.**

A tiny macOS menu bar app for memory and storage.

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-000000?style=flat&logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-orange?style=flat)](https://www.swift.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow?style=flat)](LICENSE)
[![CI](https://github.com/takeshita-0x0201/room/actions/workflows/ci.yml/badge.svg)](https://github.com/takeshita-0x0201/room)

Room is a lightweight, open-source macOS menu bar system monitor that shows your RAM usage and disk space at a glance, plus a safety-first storage cleaner for when you actually need to free up space. Unlike typical "RAM cleaners", Room never frees memory by force, never purges inactive cache, and never quits anything automatically. Instead it reads **macOS Memory Pressure** — the same signal the operating system itself uses to judge whether your Mac is genuinely running low — and only suggests action when pressure is real.

## Features

### Menu bar memory and disk monitor

Shows memory and storage usage in the menu bar with just an icon and a number, so it stays glanceable. Switch between three display modes at any time from Settings — **Percentage**, **Free**, and **Used** — and the menu bar updates instantly.

### Memory Pressure diagnosis

Room judges memory health by macOS Memory Pressure rather than raw usage alone, reporting **Normal**, **Warning**, or **Critical**. Pressure is detected event-driven via `DispatchSource` — no polling. A machine at 90% RAM with Normal pressure is simply left alone.

### Make Room for Memory

Under Warning or Critical pressure, Room lists the top high-memory apps and lets you select which ones to quit, showing the potential recovery before you confirm. It only offers this under real pressure — at Normal pressure it says *No action needed* — and it never quits an app on its own.

### Make Room for Storage

Scans regenerable data across application caches, browser caches, logs, the Trash, and developer caches — **Xcode DerivedData, npm / pnpm / yarn, Homebrew, CocoaPods, and Gradle** — and reports how much is cleanable. A Review screen always comes first: every item can be toggled on or off before anything is deleted, and after cleaning Room shows the bytes it actually deleted.

### Process list with safe Quit and Force Quit

Browse all of your processes, grouped by app, sorted by memory usage, with one-click **Quit** and **Force Quit** actions. System-critical processes — kernel tasks, the window server, Dock, SystemUIServer, and other protected system services — are always protected and cannot be quit.

### Privacy

Room is 100% local. It has zero network communication, no analytics, no telemetry, and no accounts — your data never leaves your Mac.

## Install

### Homebrew (recommended)

```bash
brew install --cask takeshita-0x0201/tap/room
```

### Manual download

Download the latest release `.zip` from the [GitHub Releases](https://github.com/takeshita-0x0201/room/releases) page, unzip it, and move `Room.app` into your `/Applications` folder.

### Unsigned build note

v0.1 builds are unsigned, so Gatekeeper will warn on first launch. Open the app by **right-clicking `Room.app` → Open**, or clear the quarantine attribute once:

```bash
xattr -dr com.apple.quarantine /Applications/Room.app
```

### Build from source

Requires Xcode 16 or later and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' build
```

## How it works

- **Memory math matches Activity Monitor.** Used memory is computed as `internal − purgeable + wired + compressor` (base 1024), so the numbers you see match the system.
- **Free space matches Finder.** Storage uses the APFS purgeable-aware `volumeAvailableCapacityForImportantUsage` metric (base 1000), the same value Finder reports.

## Safety design

Room's cleanup is built around one rule: **no deletion without Review**.

- A single Review-gated deletion path; nothing is ever removed without your confirmation.
- Every target's inode and device number are recorded at scan time and **re-verified immediately before deletion**.
- Symbolic links are never targets, and real paths are re-checked to stay under allowed roots.
- The running-app check is re-run at deletion time, so caches of apps that launched after the scan are skipped.

Full details: [docs/requirements.md](docs/requirements.md).

## Permissions

Room requires **no permissions for monitoring** — RAM, storage, and process stats all work without any grants, and Room never asks preemptively.

Full Disk Access is only needed if you want the **Trash** included in cleanup. Until you grant it in System Settings, the Trash row simply shows a "Grant Full Disk Access to include Trash" hint; nothing else is affected.

## FAQ

### Is Room a RAM cleaner or memory booster?

No. Room never frees memory by force, never purges inactive cache, and never quits anything automatically. It reads macOS Memory Pressure and only suggests quitting high-memory apps when pressure is actually Warning or Critical.

### Does Room slow down my Mac?

No. Idle CPU usage is about 0% and the app sits around 70 MB of memory. While the menu bar popover is closed, Room runs a single lightweight timer plus event-driven Memory Pressure monitoring — no continuous polling.

### Does Room collect or send any data?

No. Room is fully local with zero network communication — no analytics, no telemetry, no accounts, and no auto-update. Your data never leaves your Mac.

### Which macOS versions are supported?

macOS 14.0 (Sonoma) or later. Room is distributed as a universal binary that runs on both Apple Silicon and Intel Macs.

### Why is the app unsigned?

v0.1 is a community open-source build without Apple Developer ID signing. On first launch, right-click `Room.app` → **Open** to bypass Gatekeeper, or run `xattr -dr com.apple.quarantine /Applications/Room.app`.

### How is Room different from full system monitors?

Room is deliberately minimal: it covers RAM and storage only, with no CPU, battery, network, or temperature graphs, so the menu bar stays glanceable. Future metrics are planned as extensions rather than additions to the core.

### Is deleting caches safe?

Room only deletes regenerable data and always shows a Review screen with per-item toggles before anything is removed. Targets are application and browser caches, logs and temp files older than the configured thresholds, and developer caches (Xcode, npm/pnpm/yarn, Homebrew, CocoaPods, Gradle); caches of running apps and system-critical data are never touched.

## Requirements

- macOS 14.0 or later (Apple Silicon & Intel).
- Swift 5.9+ / SwiftUI.

## Contributing

Contributions are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for build instructions and hard rules, and the specs in [docs/requirements.md](docs/requirements.md), [docs/design-system.md](docs/design-system.md), and [docs/extensions.md](docs/extensions.md).

## License

MIT. See [LICENSE](LICENSE).
