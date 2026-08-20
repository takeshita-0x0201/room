# Room

**See what's full. Make room.**

A tiny macOS menu bar app for memory and storage.

Room sits in your menu bar and tells you, at a glance, how your RAM and storage are doing. When something is actually getting tight, it helps you make room — one small, deliberate action at a time.

> Room is not a RAM cleaner. It distinguishes "using a lot of memory" from "actually running low on memory" and treats **Memory Pressure** as the signal that matters.

## What it shows

The menu bar shows the Room icon plus one number for each metric:

```
◇ ▦72 ▱68
```

- `◇` — Room. Click to open the popover.
- `▦72` — Memory usage (72%).
- `▱68` — Storage usage (68%).

The popover shows:

- **MEMORY** — used / total, Memory Pressure (Normal / Warning / Critical), swap.
- **STORAGE** — used / total, free space.
- **TOP PROCESSES** — the top three RAM consumers, grouped by app.

Three display modes, switchable instantly from Settings:

| Mode | Example |
|------|---------|
| Percentage (default) | `◇ ▦72 ▱68` |
| Free | `◇ ▦5.6G ▱171G` |
| Used | `◇ ▦18.4G ▱341G` |

## What Make Room does

**Memory** — *Diagnose pressure. Quit what you don't need.*

- Diagnoses Memory Pressure and only suggests quitting apps when pressure is **Warning** or **Critical**.
- At Normal pressure it simply says *No action needed*.
- Room never cleans RAM artificially, never purges inactive cache, and **never quits anything automatically**. You always pick what to quit.

**Storage** — *Find what can safely go. Make room.*

- Scans regenerable content: application caches, browser caches, temporary files, old logs, trash, and developer caches (Xcode, npm/pnpm/yarn, Homebrew, CocoaPods, Gradle).
- Always shows a **Review screen** before anything is deleted — every item can be toggled on or off.
- After cleaning, shows what was **actually deleted**. Room never deletes without your confirmation.

## Requirements

- macOS 14.0 or later (Apple Silicon & Intel).

## Install

Download the latest release from this repository's GitHub Releases page. Room is unsigned for now: on first launch, **right-click the app → Open** to bypass Gatekeeper.

## Full Disk Access

Room never asks for permissions preemptively. It works fully without any grants.

Full Disk Access is only needed if you want **Trash** to be included in cleanup. Until you grant it in System Settings, the Trash row simply shows a "Grant Full Disk Access to include Trash" hint — nothing else is affected.

## Build from source

You'll need Xcode 16+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`).

```bash
xcodegen generate
open Room.xcodeproj
```

Or from the command line:

```bash
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' build
xcodebuild -project Room.xcodeproj -scheme Room -destination 'platform=macOS' test
```

## Privacy

Private by design. Room is fully local:

- Zero network communication.
- No analytics, no telemetry, no accounts.
- Your data never leaves your Mac.

## License

MIT. See [LICENSE](LICENSE).