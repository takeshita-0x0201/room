import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(13)
            RoomDivider()
            memorySection
                .padding(13)
            RoomDivider()
            storageSection
                .padding(13)
            RoomDivider()
            topProcesses
                .padding(13)
            RoomDivider()
            footer
                .padding(8)
        }
        .background(RoomPalette.canvas)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(nsImage: RoomIcon.menuBarImage(pointSize: 22))
                .accessibilityHidden(true)
            Text("Room")
                .font(.title3.weight(.semibold))
            Spacer()
            Button { openSettingsWindow() } label: {
                Image(systemName: "gearshape")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 28, height: 28)
                    .background(RoomPalette.subtleSurface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var footer: some View {
        HStack(spacing: 5) {
            footerButton(title: "Make Room",
                         icon: Image(nsImage: RoomIcon.menuBarImage(pointSize: 15))) {
                route = .makeRoom
            }
            footerButton(title: "Processes", icon: Image(systemName: "gauge")) {
                route = .processes
            }
            footerButton(title: "Settings", icon: Image(systemName: "gearshape")) {
                openSettingsWindow()
            }
        }
    }

    private func footerButton(title: String, icon: Image, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                icon
                    .frame(height: 16)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
            .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 9))
        }
        .buttonStyle(.plain)
    }

    private func openSettingsWindow() {
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }

    @ViewBuilder private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Memory", systemImage: "memorychip",
                          trailing: state.memory.map { ByteText.percent($0.usedFraction) + "%" },
                          accent: RoomPalette.memory)
            if let memory = state.memory {
                UsageBar(fraction: memory.usedFraction, tint: RoomPalette.memory)
                HStack(alignment: .firstTextBaseline) {
                    Text(ByteText.pair(used: memory.usedBytes,
                                       total: memory.totalBytes,
                                       base: .memory1024))
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                    Spacer()
                    MetricCaption(label: "Free",
                                  value: ByteText.long(memory.freeBytes, base: .memory1024))
                }
                HStack(spacing: 21) {
                    MetricCaption(label: "Pressure",
                                  value: memory.pressure.rawValue,
                                  statusColor: memory.pressure.color)
                    MetricCaption(label: "Swap",
                                  value: ByteText.long(memory.swapUsedBytes, base: .memory1024))
                }
            } else {
                loadingRow
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var storageSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Storage", systemImage: "internaldrive",
                          trailing: state.storage.map { ByteText.percent($0.usedFraction) + "%" },
                          accent: RoomPalette.storage)
            if let storage = state.storage {
                UsageBar(fraction: storage.usedFraction, tint: RoomPalette.storage)
                HStack(alignment: .firstTextBaseline) {
                    Text(ByteText.pair(used: storage.usedBytes,
                                       total: storage.totalBytes,
                                       base: .storage1000))
                        .font(.body.weight(.medium))
                        .monospacedDigit()
                    Spacer()
                    MetricCaption(label: "Free",
                                  value: ByteText.long(storage.freeBytes, base: .storage1000))
                }
            } else {
                loadingRow
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var topProcesses: some View {
        VStack(alignment: .leading, spacing: 8) {
            SectionHeader(title: "Top Processes", systemImage: "chart.bar")
            if state.processes.isEmpty {
                loadingRow
            } else {
                ForEach(state.processes.prefix(3)) { group in
                    HStack {
                        Text(group.displayName).lineLimit(1)
                        Spacer()
                        Text(ByteText.long(group.footprintBytes, base: .memory1024))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    .font(.body)
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    private var loadingRow: some View {
        HStack(spacing: 8) {
            ProgressView().controlSize(.small)
            Text("Loading…")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(minHeight: 18)
    }
}
