import SwiftUI

/// RAM 使用量降順のプロセス一覧（要件 §13–15）。
/// Quit は要求ベース — 5 秒後も生存していたら "Still running" を提示（§14.3）。
struct ProcessesView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute
    @State private var confirmingForceQuit: ProcessGroup?
    @State private var stillRunning: Set<ProcessGroup.ID> = []

    private let quitService: QuitServicing = QuitService()
    private let policy = ProcessProtectionPolicy(
        currentUid: getuid(),
        ownPid: ProcessInfo.processInfo.processIdentifier)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BackHeader(title: "Processes", route: $route, back: .home)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(state.processes.prefix(30)) { group in
                        row(for: group)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .padding(12)
        .confirmationDialog(
            "Force Quit \(confirmingForceQuit?.displayName ?? "")?",
            isPresented: .init(get: { confirmingForceQuit != nil },
                               set: { if !$0 { confirmingForceQuit = nil } }),
            titleVisibility: .visible
        ) {
            Button("Force Quit", role: .destructive) {
                if let group = confirmingForceQuit {
                    quitService.forceQuit(group)
                    scheduleRecheck(group)
                }
                confirmingForceQuit = nil
            }
            Button("Cancel", role: .cancel) { confirmingForceQuit = nil }
        } message: {
            Text("Unsaved changes may be lost.")
        }
    }

    @ViewBuilder private func row(for group: ProcessGroup) -> some View {
        let quittable = policy.canQuit(group)
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(group.displayName).lineLimit(1)
                if stillRunning.contains(group.id) {
                    Text("Still running").font(.caption2).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(ByteText.long(group.footprintBytes, base: .memory1024))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            Menu {
                Button("Quit") { quit(group) }
                Button("Force Quit", role: .destructive) { confirmingForceQuit = group }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 24)
            .disabled(!quittable)
            .accessibilityLabel("Actions for \(group.displayName)")
        }
        .font(.callout)
        .padding(.vertical, 2)
    }

    private func quit(_ group: ProcessGroup) {
        quitService.requestQuit(group)
        scheduleRecheck(group)
    }

    private func scheduleRecheck(_ group: ProcessGroup) {
        stillRunning.remove(group.id)
        Task {
            try? await Task.sleep(for: .seconds(5))
            if quitService.isRunning(group) {
                stillRunning.insert(group.id)
            }
            state.refreshProcesses()
        }
    }
}
