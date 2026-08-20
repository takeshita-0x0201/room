import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 21) {
            header
            memorySection
            storageSection
            topProcesses
            footer
        }
        .padding(13)
    }

    private var header: some View {
        HStack(spacing: 5) {
            Image(nsImage: RoomIcon.menuBarImage(pointSize: 22))
                .accessibilityHidden(true)
            Text("Room").font(.title3.weight(.semibold))
            Spacer()
            Button { openSettingsWindow() } label: {
                Image(systemName: "gearshape")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var footer: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
            NavRow(icon: Image(nsImage: RoomIcon.menuBarImage()), title: "Make Room") {
                route = .makeRoom
            }
            NavRow(icon: Image(systemName: "gauge"), title: "Processes", showsChevron: true) {
                route = .processes
            }
            NavRow(icon: Image(systemName: "gearshape"), title: "Settings") {
                openSettingsWindow()
            }
        }
    }

    private func openSettingsWindow() {
        openSettings()
        NSApp.activate(ignoringOtherApps: true)
    }

    @ViewBuilder private var memorySection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Memory", systemImage: "memorychip",
                          trailing: state.memory.map { ByteText.percent($0.usedFraction) + "%" })
            if let m = state.memory {
                UsageBar(fraction: m.usedFraction, tint: .blue)
                Text(ByteText.pair(used: m.usedBytes, total: m.totalBytes, base: .memory1024))
                    .font(.body).monospacedDigit()
                StatRow(label: "Free", value: ByteText.long(m.freeBytes, base: .memory1024))
                PressureRow(pressure: m.pressure)
                StatRow(label: "Swap", value: ByteText.long(m.swapUsedBytes, base: .memory1024))
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var storageSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Storage", systemImage: "internaldrive",
                          trailing: state.storage.map { ByteText.percent($0.usedFraction) + "%" })
            if let s = state.storage {
                UsageBar(fraction: s.usedFraction, tint: .green)
                Text(ByteText.pair(used: s.usedBytes, total: s.totalBytes, base: .storage1000))
                    .font(.body).monospacedDigit()
                StatRow(label: "Free", value: ByteText.long(s.freeBytes, base: .storage1000))
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var topProcesses: some View {
        VStack(alignment: .leading, spacing: 5) {
            SectionHeader(title: "Top Processes", systemImage: "chart.bar")
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