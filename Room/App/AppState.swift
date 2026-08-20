import AppKit
import Observation

/// The app's single state hub. Refresh policy (requirements §19):
/// - RAM/SSD stats: refreshed periodically on a Refresh Interval timer (lightweight)
/// - Memory Pressure: DispatchSource event-driven (no polling)
/// - Process list: refreshed only when the Popover opens and after Quit operations
///   (no periodic rebuild while displayed, since rebuilding rows would steal click actions)
@Observable
@MainActor
final class AppState {
    var memory: MemorySnapshot?
    var storage: StorageSnapshot?
    var processes: [ProcessGroup] = []
    /// Total that the latest Storage scan found "deletable right now" (for the §16 hub display).
    /// Reset to nil after a Clean runs so the display stays static until the next scan.
    var lastCleanupReadyBytes: UInt64?
    var isPopoverVisible = false {
        didSet {
            if isPopoverVisible {
                refreshProcesses()
            } else {
                processRefreshTask?.cancel()   // stop an in-flight enumeration when closed
            }
        }
    }

    @ObservationIgnored private let memoryService: MemoryStatsProviding
    @ObservationIgnored private let storageService: StorageStatsProviding
    @ObservationIgnored private let processService: ProcessListProviding
    @ObservationIgnored private var pressureSource: DispatchSourceMemoryPressure?
    @ObservationIgnored private var refreshTask: Task<Void, Never>?
    @ObservationIgnored private var processRefreshTask: Task<Void, Never>?

    init(memoryService: MemoryStatsProviding = MemoryService(),
         storageService: StorageStatsProviding = StorageService(),
         processService: ProcessListProviding = ProcessService()) {
        self.memoryService = memoryService
        self.storageService = storageService
        self.processService = processService
        refreshStats()
        observePressure()
        startRefreshLoop()
    }

    func refreshNow() {
        refreshStats()
    }

    func refreshStats() {
        // Don't reassign unless the value changed — avoids no-change redraws (a cause of stolen clicks)
        let newMemory = memoryService.snapshot()
        if newMemory != memory { memory = newMemory }
        let newStorage = storageService.snapshot()
        if newStorage != storage { storage = newStorage }
    }

    func refreshProcesses() {
        guard isPopoverVisible else { return }   // prevent starting an enumeration after the Popover closes (requirements §19)
        processRefreshTask?.cancel()   // so a stale task's late result doesn't overwrite the new one
        let service = processService
        processRefreshTask = Task.detached(priority: .utility) { [weak self] in
            let groups = service.groups()
            guard !Task.isCancelled else { return }
            await MainActor.run { self?.processes = groups }
        }
    }

    private func startRefreshLoop() {
        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                let seconds = max(5, UserDefaults.standard.integer(forKey: SettingsKey.refreshInterval))
                try? await Task.sleep(for: .seconds(seconds))
                self?.refreshNow()
            }
        }
    }

    private func observePressure() {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.normal, .warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in self?.refreshStats() }
        source.resume()
        pressureSource = source
    }
}
