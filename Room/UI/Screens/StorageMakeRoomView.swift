import SwiftUI

/// Storage Make Room (requirements §18.6). Both the Make Room and Review buttons
/// always go through the Review (confirmation) screen — there is no deletion path without confirmation.
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
    /// Prevents concurrent Cleans on screen re-entry (guarantees the only Clean run in the process)
    @MainActor private static var isCleaning = false

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            if case .cleaning = phase {
                Text("Make Room — Storage").font(.headline)
            } else {
                BackHeader(title: "Make Room — Storage", route: $route, back: .makeRoom)
            }
            content
        }
        .padding(13)
        .background(RoomPalette.canvas)
        .onAppear { startScan() }
        .onDisappear { scanTask?.cancel() }
    }

    @ViewBuilder private var content: some View {
        switch phase {
        case .scanning:
            VStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Scanning regenerable files…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
            .background(RoomPalette.storage.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 13))
        case .results(let items):
            resultsView(items)
        case .reviewing(let items):
            reviewView(items)
        case .cleaning:
            VStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Making room…").foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        case .done(let outcome):
            doneView(outcome)
        }
    }

    @ViewBuilder private func resultsView(_ items: [CleanupItem]) -> some View {
        if let s = state.storage {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: "Storage", systemImage: "internaldrive",
                              trailing: ByteText.percent(s.usedFraction) + "%",
                              accent: RoomPalette.storage)
                UsageBar(fraction: s.usedFraction, tint: RoomPalette.storage)
                StatRow(label: "Used",
                        value: ByteText.pair(used: s.usedBytes,
                                             total: s.totalBytes,
                                             base: .storage1000))
                StatRow(label: "Free", value: ByteText.long(s.freeBytes, base: .storage1000))
            }
            .padding(13)
            .background(RoomPalette.storage.opacity(0.07),
                        in: RoundedRectangle(cornerRadius: 13))
        }

        SectionHeader(title: "Cleanable")
        // Total sums only what can be deleted right now (requirements D22: don't pad it with blocked / FDA items)
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
            .fontWeight(.medium)
            .padding(10)
            .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 9))

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
            // The primary action is a single blue Review button (design-system §8). Deletion always goes through Review
            Button("Review") { beginReview(items) }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .keyboardShortcut(.defaultAction)
        }
        .disabled(!items.contains { $0.state == .ready })
    }

    @ViewBuilder private func reviewView(_ items: [CleanupItem]) -> some View {
        SectionHeader(title: "Review")
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
                .padding(8)
                .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 8))
            case .blocked(let app):
                HStack {
                    Text(item.title).foregroundStyle(.secondary)
                    Spacer()
                    Text("Quit \(app) to clean").font(.caption).foregroundStyle(.secondary)
                }
                .accessibilityElement(children: .combine)
            case .needsFullDiskAccess:
                EmptyView()   // already guided on the resultsView side
            }
        }

        let selectedTotal = items
            .filter { $0.state == .ready && enabledIDs.contains($0.id) }
            .reduce(UInt64(0)) { $0 + $1.sizeBytes }
        StatRow(label: "Total", value: ByteText.long(selectedTotal, base: .storage1000))
            .fontWeight(.medium)
            .padding(10)
            .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 9))

        HStack {
            Spacer()
            Button("Cancel") { phase = .results(items) }
            Button("Clean") { clean(items) }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(enabledIDs.isEmpty)
        }
    }

    @ViewBuilder private func doneView(_ outcome: CleanupOutcome) -> some View {
        // Fact-based result display (total size of deleted files).
        // APFS free-space updates are delayed, so the freeAfter delta is not shown as the result (requirements D22)
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
