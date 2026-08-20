import SwiftUI

/// Memory Pressure Manager (requirements §17).
/// Normal → "No action needed". Warning/Critical → select high-memory processes to quit.
struct MemoryMakeRoomView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute
    @State private var selection: Set<ProcessGroup.ID> = []

    private let quitService: QuitServicing = QuitService()
    private let policy = ProcessProtectionPolicy(
        currentUid: getuid(),
        ownPid: ProcessInfo.processInfo.processIdentifier)
    private static let minimumFootprint: UInt64 = 200 * 1024 * 1024   // under 200 MB is not a candidate

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            BackHeader(title: "Make Room — Memory", route: $route, back: .makeRoom)

            if let memory = state.memory {
                PressureRow(pressure: memory.pressure)
                StatRow(label: "Swap",
                        value: ByteText.long(memory.swapUsedBytes, base: .memory1024))

                switch memory.pressure {
                case .normal:
                    Text("No action needed")
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                case .unavailable:
                    // Don't let an unavailable reading read as "no problem" (requirements D21)
                    Text("Pressure unavailable")
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                case .warning, .critical:
                    selectionList
                }
            }
        }
        .padding(13)
    }

    private var candidates: [ProcessGroup] {
        state.processes
            .filter { policy.canQuit($0) && $0.footprintBytes >= Self.minimumFootprint }
            .prefix(8)
            .map { $0 }
    }

    private var potentialRecovery: UInt64 {
        candidates.filter { selection.contains($0.id) }
            .reduce(0) { $0 + $1.footprintBytes }
    }

    @ViewBuilder private var selectionList: some View {
        Text("Select apps to quit")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.top, 4)

        ForEach(candidates) { group in
            Toggle(isOn: .init(
                get: { selection.contains(group.id) },
                set: { on in if on { selection.insert(group.id) } else { selection.remove(group.id) } }
            )) {
                HStack {
                    Text(group.displayName).lineLimit(1)
                    Spacer()
                    Text(ByteText.long(group.footprintBytes, base: .memory1024))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .toggleStyle(.checkbox)
        }

        // Never present as a guaranteed recovery (requirements §17.4) — keep the "Potential" wording
        StatRow(label: "Potential recovery",
                value: ByteText.long(potentialRecovery, base: .memory1024))
            .padding(.top, 4)

        HStack {
            Spacer()
            Button("Quit Selected") { quitSelected() }
                .disabled(selection.isEmpty)
                .keyboardShortcut(.defaultAction)
        }
    }

    private func quitSelected() {
        for group in candidates where selection.contains(group.id) {
            quitService.requestQuit(group)
        }
        selection.removeAll()
        Task {
            try? await Task.sleep(for: .seconds(3))
            state.refreshNow()
        }
        route = .makeRoom
    }
}
