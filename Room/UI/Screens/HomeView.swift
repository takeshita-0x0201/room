import SwiftUI

struct HomeView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 6) {
                Image(systemName: "cube.transparent")
                Text("Room").font(.headline)
            }

            memorySection
            storageSection
            topProcesses

            Divider()

            NavRow(systemImage: "cube.transparent", title: "Make Room") { route = .makeRoom }
            NavRow(systemImage: "circle.grid.2x2", title: "Processes", showsChevron: true) { route = .processes }
            NavRow(systemImage: "gearshape", title: "Settings") {
                openSettings()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .padding(12)
    }

    @ViewBuilder private var memorySection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "MEMORY",
                          trailing: state.memory.map { ByteText.percent($0.usedFraction) + "%" })
            if let m = state.memory {
                Text(ByteText.pair(used: m.usedBytes, total: m.totalBytes, base: .memory1024))
                    .font(.callout).monospacedDigit()
                StatRow(label: "Pressure", value: m.pressure.rawValue, valueColor: m.pressure.color)
                StatRow(label: "Swap", value: ByteText.long(m.swapUsedBytes, base: .memory1024))
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var storageSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "STORAGE",
                          trailing: state.storage.map { ByteText.percent($0.usedFraction) + "%" })
            if let s = state.storage {
                Text(ByteText.pair(used: s.usedBytes, total: s.totalBytes, base: .storage1000))
                    .font(.callout).monospacedDigit()
                StatRow(label: "Free", value: ByteText.long(s.freeBytes, base: .storage1000))
            }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var topProcesses: some View {
        VStack(alignment: .leading, spacing: 4) {
            SectionHeader(title: "TOP PROCESSES")
            ForEach(state.processes.prefix(3)) { group in
                StatRow(label: group.displayName,
                        value: ByteText.long(group.footprintBytes, base: .memory1024))
            }
        }
    }
}
