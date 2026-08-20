import AppKit
import Observation

/// アプリ唯一の状態ハブ。更新ポリシー（要件 §19 Refresh Policy）:
/// - RAM/SSD 統計: Refresh Interval のタイマーで定期更新（軽量）
/// - Memory Pressure: DispatchSource イベント駆動（ポーリングなし）
/// - プロセス一覧: Popover 表示中のみ更新（高コスト）
@Observable
@MainActor
final class AppState {
    var memory: MemorySnapshot?
    var storage: StorageSnapshot?
    var processes: [ProcessGroup] = []
    /// 直近の Storage スキャンで「今すぐ削除可能」だった合計（要件 §16 のハブ表示用）。
    /// Clean 実行後は nil に戻し、次回スキャンまで静的表示にする。
    var lastCleanupReadyBytes: UInt64?
    var isPopoverVisible = false {
        didSet {
            if isPopoverVisible {
                refreshProcesses()
            } else {
                processRefreshTask?.cancel()   // 閉じたら進行中の列挙を止める
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
        if isPopoverVisible { refreshProcesses() }
    }

    func refreshStats() {
        memory = memoryService.snapshot()
        storage = storageService.snapshot()
    }

    func refreshProcesses() {
        guard isPopoverVisible else { return }   // Popover 閉鎖後の列挙開始を防ぐ（要件 §19）
        processRefreshTask?.cancel()   // 旧タスクの遅延結果が新結果を上書きしないように
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
