import SwiftUI

/// Storage Make Room（要件 §18.6）。Make Room / Review どちらのボタンも
/// 必ず Review（確認画面）を経由する — 確認なしの削除経路は存在しない。
struct StorageMakeRoomView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute

    private let cleanup: CleanupScanning & CleanupDeleting = CleanupService()

    enum Phase {
        case scanning
        case results([CleanupItem])
        case reviewing([CleanupItem])
        case cleaning
        case done(CleanupOutcome)
    }

    @State private var phase: Phase = .scanning
    @State private var enabledIDs: Set<String> = []
    @State private var scanTask: Task<Void, Never>?
    /// 画面再入時の並行 Clean を防ぐ（プロセス内で唯一の Clean 実行を保証）
    @MainActor private static var isCleaning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if case .cleaning = phase {
                Text("Make Room — Storage").font(.headline)
            } else {
                BackHeader(title: "Make Room — Storage", route: $route, back: .makeRoom)
            }
            content
        }
        .padding(12)
        .onAppear { startScan() }
        .onDisappear { scanTask?.cancel() }
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .scanning:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Scanning…").foregroundStyle(.secondary)
            }
        case .results(let items):
            resultsView(items)
        case .reviewing(let items):
            reviewView(items)
        case .cleaning:
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text("Cleaning…").foregroundStyle(.secondary)
            }
        case .done(let outcome):
            doneView(outcome)
        }
    }

    @ViewBuilder private func resultsView(_ items: [CleanupItem]) -> some View {
        if let s = state.storage {
            Text(ByteText.pair(used: s.usedBytes, total: s.totalBytes, base: .storage1000))
                .font(.callout).monospacedDigit()
            StatRow(label: "Free", value: ByteText.long(s.freeBytes, base: .storage1000))
        }

        SectionHeader(title: "CLEANABLE")
        // Total は「今すぐ消せる量」だけを合算（要件 D22: blocked / FDA を混ぜて水増ししない）
        let ready = items.filter { $0.state == .ready }
        let totals = CleanupSummary.totals(ready)
        ForEach(CleanupSummaryGroup.allCases, id: \.self) { group in
            if let bytes = totals[group], bytes > 0 {
                StatRow(label: group.rawValue,
                        value: ByteText.long(bytes, base: .storage1000))
            }
        }
        StatRow(label: "Total",
                value: ByteText.long(CleanupSummary.grandTotal(ready), base: .storage1000))

        let blockedBytes = CleanupSummary.grandTotal(items.filter {
            if case .blocked = $0.state { return true }
            return false
        })
        if blockedBytes > 0 {
            Text("+ \(ByteText.long(blockedBytes, base: .storage1000)) after quitting apps")
                .font(.caption).foregroundStyle(.secondary)
        }
        if items.contains(where: { $0.state == .needsFullDiskAccess }) {
            Button("Grant Full Disk Access to include Trash…") { openFullDiskAccessSettings() }
                .font(.caption)
                .buttonStyle(.link)
        }

        HStack {
            Spacer()
            Button("Review") { beginReview(items) }
            Button("Make Room") { beginReview(items) }   // どちらも Review 経由（削除の直行路なし）
                .keyboardShortcut(.defaultAction)
        }
        .disabled(!items.contains { $0.state == .ready })
    }

    @ViewBuilder private func reviewView(_ items: [CleanupItem]) -> some View {
        SectionHeader(title: "REVIEW")
        ForEach(items) { item in
            switch item.state {
            case .ready:
                Toggle(isOn: .init(
                    get: { enabledIDs.contains(item.id) },
                    set: { on in if on { enabledIDs.insert(item.id) } else { enabledIDs.remove(item.id) } }
                )) {
                    HStack {
                        Text(item.title).lineLimit(1)
                        Spacer()
                        Text(ByteText.long(item.sizeBytes, base: .storage1000))
                            .monospacedDigit().foregroundStyle(.secondary)
                    }
                }
                .toggleStyle(.checkbox)
            case .blocked(let app):
                HStack {
                    Text(item.title).foregroundStyle(.secondary)
                    Spacer()
                    Text("Quit \(app) to clean").font(.caption).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            case .needsFullDiskAccess:
                EmptyView()   // resultsView 側で案内済み
            }
        }

        let selectedTotal = items
            .filter { $0.state == .ready && enabledIDs.contains($0.id) }
            .reduce(UInt64(0)) { $0 + $1.sizeBytes }
        StatRow(label: "Total", value: ByteText.long(selectedTotal, base: .storage1000))

        HStack {
            Spacer()
            Button("Cancel") { phase = .results(items) }
            Button("Clean") { clean(items) }
                .keyboardShortcut(.defaultAction)
                .disabled(enabledIDs.isEmpty)
        }
    }

    @ViewBuilder private func doneView(_ outcome: CleanupOutcome) -> some View {
        // 事実ベースの実績表示（削除したファイルサイズ合計）。
        // APFS の空き容量反映は遅延するため freeAfter 差分を成果として出さない（要件 D22）
        StatRow(label: "Cleaned",
                value: ByteText.long(outcome.deletedBytes, base: .storage1000))
        if let s = state.storage {
            StatRow(label: "Free now", value: ByteText.long(s.freeBytes, base: .storage1000))
        }
        if !outcome.skippedPaths.isEmpty {
            Text("Skipped \(outcome.skippedPaths.count) items")
                .font(.caption).foregroundStyle(.secondary)
        }
        HStack {
            Spacer()
            Button("Done") { route = .makeRoom }
                .keyboardShortcut(.defaultAction)
        }
    }

    private func startScan() {
        phase = .scanning
        scanTask = Task {
            let items = await cleanup.scan()
            if Task.isCancelled { return }
            phase = .results(items)
            state.lastCleanupReadyBytes = CleanupSummary.grandTotal(items.filter { $0.state == .ready })
        }
    }

    private func beginReview(_ items: [CleanupItem]) {
        enabledIDs = Set(items.filter { $0.state == .ready }.map(\.id))
        phase = .reviewing(items)
    }

    private func clean(_ items: [CleanupItem]) {
        guard !Self.isCleaning else { return }
        Self.isCleaning = true
        let selected = items.filter { $0.state == .ready && enabledIDs.contains($0.id) }
        phase = .cleaning
        Task {
            let outcome = await cleanup.delete(selected)
            Self.isCleaning = false
            phase = .done(outcome)
            state.lastCleanupReadyBytes = nil
            state.refreshStats()
        }
    }

    private func openFullDiskAccessSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
    }
}