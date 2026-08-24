# Room Design System v1.0

> Source: user-provided design sheet (2026-08-20). This document is authoritative for UI design.
> The functional spec's authority is `requirements.md` (this document only defines "how things look").

## 1. Brand Icon (Room)

- Motif: **frameless spatial volume** — wireframe of only three faces: the bottom + the back-left + the back-right
- Principles: unfilled faces / monochrome / geometric / recognizable at small sizes (16–18px) / Light & Dark support (Template Image)
- Meaning: space, whitespace, free space, Room (app identification)
- Implementation: `Room/UI/Icons/RoomIcon.swift` (NSBezierPath, isTemplate)

## 2. Icon Set (Unified Design Language)

| Icon | Meaning | v0.1 implementation | Future |
|---|---|---|---|
| Room (wireframe room) | App identification | RoomIcon | — |
| Memory (vertical module glyph) | RAM status | SF Symbols `memorychip` | Custom glyph (line weight & corner radius unified with the Room icon) |
| Storage (drive glyph) | SSD status | SF Symbols `internaldrive` | Same as above |

Policy: match line weight, corner radius, and abstraction to the brand icon so the three read as one language.

## 3. Color

| Use | Color |
|---|---|
| Accent / primary action (Review button, selection state) | System accent color |
| Memory usage bar | Muted slate blue (`#5D7F9F` light) |
| Storage usage bar | Muted eucalyptus (`#5C8974` light) |
| Pressure: Normal | **Muted slate blue** dot |
| Pressure: Warning | Muted ochre |
| Pressure: Critical | Muted red |
| Canvas / surfaces | Warm off-white inspired by the landing page; adaptive charcoal in Dark Mode |
| Text | System primary / secondary, auto Light / Dark |

- State is **always paired with text** (never communicate by color alone — accessibility principle preserved)
- **Pressure is shown as a "colored dot (●) + normal-color text"**. The status text itself is not colored (2026-08-20 feedback; per the sheet's "Memory Pressure status expression")
- Note: the v1.1 requirement's "achromatic in normal state" principle is revised by this design decision (allowing Normal blue and always-on usage-bar color)

## 4. Number Format

| Context | Format | Example |
|---|---|---|
| Menu bar (compact) | One-letter unit, one decimal below 100 | `824M` `3.2G` `171G` `1.2T` |
| Popover (detailed) | Unit + space | `824 MB` `3.2 GB` `171 GB` `1.2 TB` |

- **Add TB-range support** (current ByteText stops at G)
- Monospaced digits required

## 5. Menu Bar Display

```
[Memory]72 [Storage]68
```

- Icon + number only. No unit, %, or label text
- **The Room icon is not shown in the menu bar** (2026-08-20 on-device feedback). Only when both Show Memory and Show Storage are OFF is the Room icon shown alone, to keep the item clickable
- Display modes: Percentage (default) → `72 / 68`, Free → `5.6G / 171G`, Used → `18.4G / 341G`
- **Implementation constraint**: SwiftUI `MenuBarExtra` labels don't render multiple Image/Text correctly (they degenerate to the first image + one text). So the menu bar label is drawn by **compositing all elements into a single template NSImage** (`MenuBarLabelRenderer`). Numbers are drawn with a monospaced digit font to prevent width jitter

## 6. Main Popover

- **Header**: Room icon + `Room` + gear at the right edge (Settings shortcut)
- **Memory / Storage are stacked in a single column** (the 2-column card was dropped per 2026-08-20 feedback; popover width is 320px):
  - Heading is **Title Case, not bold, body size** (icon and text at the same size; 2026-08-20 feedback) + `%` on the right (**the % is also not bold, body size**)
  - The header's Room icon (22pt) + "Room" (title3 semibold) are slightly larger
  - **Usage progress bar** (Memory=blue / Storage=green, thin, rounded)
  - `used / total`
  - Memory side: `Pressure <status>` (colored dot + normal-color status word) + `Swap`
  - Storage side: `Free`
- **Top Processes**: name + usage only (top 3. App icons dropped — simplified per 2026-08-20 feedback)
- **Footer row**: two flat actions matching the landing-page preview — `Make Room` (Room icon) / `Processes` (gauge icon). Settings remains available from the header gear.

## 7. Processes List

- Row structure: name + usage + **inline `Quit` / `Force Quit` buttons** (subtle bordered style. App icons dropped — 2026-08-20 feedback)
- **While Quit / Force Quit is running, the two buttons are replaced by a small circular spinner (the macOS standard dotted progress indicator)**. When the liveness check (~5 seconds) completes, the row disappears if the process quit, or returns to "Still running" + buttons if not
- Protected targets have the relevant buttons grayed out (e.g., Finder's Force Quit disabled)
- The ellipsis-menu approach is dropped (one-click operation)

## 8. Make Room > Storage

- Category rows: name + size + chevron
- `Total` row + **blue `Review` button** on the right (primary action / borderedProminent)

## 9. Settings > Display

- **Preview chip** to the right of each radio row (Memory & Storage icons + fixed sample values, rounded background. No Room icon — to match the actual menu bar display)
  - Percentage: `72 / 68`, Free: `5.6G / 171G`, Used: `18.4G / 341G`
- Refresh Interval is a pop-up menu (`5 sec`)

## 10. Spacing Scale (golden-ratio based)

Use the Fibonacci scale **3 / 5 / 8 / 13 / 21** derived from the φ (≈1.618) chain (adjacent ratios ≈ φ) across all screens (shrunk one step from 4/6/10/16/26 per 2026-08-20 feedback; ratios unchanged):

| Value | Use |
|---|---|
| 3 | Micro-gap between icon and text |
| 5 | Line spacing between stat rows |
| 8 | Footer row spacing, chip inner padding |
| 13 | Screen outer padding |
| 21 | Between sections |

Body text uses `.body`, captions use `.caption` (`.callout` is not used — readability first, 2026-08-20 feedback).

## 11. Implementation Phases (v0.1.x design reflection)

| Phase | Contents |
|---|---|
| D1 | Foundation: ByteText TB support / Pressure colors (Normal=blue) / UsageBar component / app-icon helper |
| D2 | Popover: 2-column card + bars + header gear + TOP PROCESSES icons + footer-row icons (later revised by D10/D11: single column, icon-free rows) |
| D3 | Processes: icon + inline button row |
| D4 | Make Room Storage: category rows + blue Review / Settings: preview chips + pop-up |
| D5 (future) | Custom Memory / Storage glyphs |
