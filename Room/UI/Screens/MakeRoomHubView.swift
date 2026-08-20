import SwiftUI

struct MakeRoomHubView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackHeader(title: "Make Room", route: $route, back: .home)

            NavRow(systemImage: "memorychip", title: "Memory", showsChevron: true) {
                route = .memoryMakeRoom
            }
            if let m = state.memory {
                Text(hubCaption(for: m.pressure))
                    .font(.caption)
                    .foregroundStyle(m.pressure == .warning || m.pressure == .critical
                                     ? m.pressure.color : Color.secondary)
            }

            Divider()

            NavRow(systemImage: "internaldrive", title: "Storage", showsChevron: true) {
                route = .storageMakeRoom
            }
            Text("Scan for cleanable files")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
    }

    private func hubCaption(for pressure: MemoryPressureLevel) -> String {
        switch pressure {
        case .normal: "Pressure Normal — No action needed"
        case .warning, .critical: "Pressure \(pressure.rawValue)"
        case .unavailable: "Pressure unavailable"
        }
    }
}
