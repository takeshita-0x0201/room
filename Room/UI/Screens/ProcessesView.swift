import SwiftUI

/// Process list sorted by RAM usage descending (requirements §13–15).
/// Quit is request-based — if it survives after 5 seconds, show "Still running" (§14.3).
struct ProcessesView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute
    @State private var confirmingForceQuit: ProcessGroup?
    @State private var stillRunning: Set<ProcessGroup.ID> = []
    @State private var quitting: Set<ProcessGroup.ID> = []

    private let quitService: QuitServicing = QuitService()
    private let policy = ProcessProtectionPolicy(
        currentUid: getuid(),
        ownPid: ProcessInfo.processInfo.processIdentifier)

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            BackHeader(title: "Processes", route: $route, back: .home)
            Text("Memory footprint by app")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 5) {
                    ForEach(state.processes.prefix(30)) { group in
                        row(for: group)
                    }
                }
            }
            .frame(maxHeight: 320)
        }
        .padding(13)
        .background(RoomPalette.canvas)
        .confirmationDialog(
            "Force Quit \(confirmingForceQuit?.displayName ?? "")?",
            isPresented: .init(get: { confirmingForceQuit != nil },
                               set: { if !$0 { confirmingForceQuit = nil } }),
            titleVisibility: .visible
        ) {
            Button("Force Quit", role: .destructive) {
                if let group = confirmingForceQuit {
                    quitting.insert(group.id)
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
        // System apps like Finder where "quit" is allowed but "force quit" is not (design-system §7)
        let forceQuittable = quittable
            && !ProcessProtectionPolicy.allowedSystemApps.contains(group.displayName)
        HStack(spacing: 5) {
            VStack(alignment: .leading, spacing: 2) {
                Text(group.displayName)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if stillRunning.contains(group.id) {
                    Text("Still running")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 3)
            Text(ByteText.long(group.footprintBytes, base: .memory1024))
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
            if quitting.contains(group.id) {
                // Show a spinner while the Quit request is pending (design-system §7)
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 94, alignment: .center)
                    .accessibilityLabel("Quitting \(group.displayName)")
            } else {
                Button("Quit") { quit(group) }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(!quittable)
                Button("Force Quit") { confirmingForceQuit = group }
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
                    .disabled(!forceQuittable)
            }
        }
        .font(.body)
        .padding(10)
        .background(RoomPalette.surface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(RoomPalette.hairline, lineWidth: 1)
        }
    }

    private func quit(_ group: ProcessGroup) {
        quitting.insert(group.id)
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
            quitting.remove(group.id)
            state.refreshProcesses()
        }
    }
}
