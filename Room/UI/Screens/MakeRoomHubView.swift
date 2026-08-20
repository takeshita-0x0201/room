import SwiftUI

struct MakeRoomHubView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            BackHeader(title: "Make Room", route: $route, back: .home)

            NavRow(icon: Image(systemName: "memorychip"), title: "Memory", showsChevron: true) {
                route = .memoryMakeRoom
            }
            if let m = state.memory {
                Text(hubCaption(for: m.pressure))
                    .font(.caption)
                    .foregroundStyle(m.pressure == .warning || m.pressure == .critical
                                     ? m.pressure.color : Color.secondary)
            }

            Divider()

            NavRow(icon: Image(systemName: "internaldrive"), title: "Storage", showsChevron: true) {
                route = .storageMakeRoom
            }
            Text(storageCaption)
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

    private var storageCaption: String {
        if let bytes = state.lastCleanupReadyBytes, bytes > 0 {
            return "\(ByteText.long(bytes, base: .storage1000)) cleanable"
        }
        return "Scan for cleanable files"
    }
}
