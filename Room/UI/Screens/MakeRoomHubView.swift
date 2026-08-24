import SwiftUI

struct MakeRoomHubView: View {
    @Environment(AppState.self) private var state
    @Binding var route: PopoverRoute

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            BackHeader(title: "Make Room", route: $route, back: .home)
            Text("Choose where you need breathing room.")
                .font(.caption)
                .foregroundStyle(.secondary)
            destination(title: "Memory",
                        caption: memoryCaption,
                        systemImage: "memorychip",
                        tint: RoomPalette.memory) {
                route = .memoryMakeRoom
            }
            destination(title: "Storage",
                        caption: storageCaption,
                        systemImage: "internaldrive",
                        tint: RoomPalette.storage) {
                route = .storageMakeRoom
            }
        }
        .padding(13)
        .background(RoomPalette.canvas)
    }

    private func destination(title: String,
                             caption: String,
                             systemImage: String,
                             tint: Color,
                             action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 13) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(tint)
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.11), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.body.weight(.medium))
                    Text(caption)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(13)
            .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 13))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var memoryCaption: String {
        guard let memory = state.memory else { return "Checking Memory Pressure…" }
        return hubCaption(for: memory.pressure)
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
        return "Scan regenerable files"
    }
}
