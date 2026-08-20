# Extending Room

Room's v0.1 extension model is **structural, not pluggable**. There is deliberately no plugin runtime yet (see requirements §3 and §20): a plugin runtime may come later, but the codebase is organized so that adding a new metric stays a small, contained change. Memory (`MemoryService` / `MemorySnapshot`) and Storage (`StorageService` / `StorageSnapshot`) are the reference implementations to copy.

## How the code is partitioned

Two rules keep Room small and testable:

- **`Room/Core`** — pure logic that can be unit-tested with Foundation only: formatting, aggregation, protection policy, cleanup rules. No system calls, no I/O.
- **`Room/Services`** — thin adapters that isolate system APIs (mach, sysctl, libproc, FileManager) behind protocols. Views and Core never call system APIs directly.

Everything new should fit one of those two layers.

## Adding a new metric (CPU, battery, network, …)

A new metric is four small steps:

1. **Service** — add a protocol + implementation in `Room/Services/` (e.g. `CPUStatsProviding` / `CpuService`). All system calls stay here, isolated behind the protocol. Follow `MemoryService`'s pattern: protocol first, implementation behind it.
2. **Model** — add a snapshot model in `Room/Models/` (e.g. `CpuSnapshot`), following `MemorySnapshot`. Keep derived values (fractions, formatted text) as computed properties so they stay pure and testable.
3. **UI** — add a section or screen in `Room/UI/Screens/` (and a reusable component in `Components/` if needed). The view reads from state only — it does not fetch anything itself.
4. **Wire it up** — expose the new snapshot in `Room/App/AppState.swift` and inject the service through the initializer, the same way `memoryService` / `storageService` are injected today.

Core stays small; anything that *computes* from the snapshot belongs in `Room/Core` with unit tests.

## What goes where — deciding factor

| Question | Put it in |
|----------|----------|
| Does it touch the OS, hardware, files, or other processes? | `Room/Services` (thin adapter, protocol + impl) |
| Does it compute, format, filter, or decide something? | `Room/Core` (pure, unit-tested) |
| Does it display something? | `Room/UI` |
| Does it hold together the app's state and refresh policy? | `Room/App` |

## Future extensions

The current out-of-scope list (requirements §3, §20) is a good roadmap:

- CPU / GPU, Battery, Network, Temperature
- Docker cache cleanup
- Community modules

No plugin runtime exists in v0.1, and none of these extensions should be bolted onto the app's main loop. A plugin runtime may be introduced later — until then, adding a metric means following the four steps above.