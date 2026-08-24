import AppKit
import SwiftUI

enum RoomPalette {
    // The landing page palette translated into quieter, adaptive macOS colors.
    // Values intentionally carry more gray than systemBlue/systemGreen.
    static let memory = adaptive(light: 0x5D7F9F, dark: 0x86A4BE)
    static let storage = adaptive(light: 0x5C8974, dark: 0x84AC99)
    static let warning = adaptive(light: 0xA7834D, dark: 0xC5A46D)
    static let critical = adaptive(light: 0xA86461, dark: 0xCB8580)
    static let canvas = adaptive(light: 0xF5F4F0, dark: 0x1D1F1D)
    static let surface = adaptive(light: 0xFFFEFA, dark: 0x272927)
    static let subtleSurface = adaptive(light: 0xECEBE6, dark: 0x2C2E2C)
    static let hairline = adaptive(light: 0xD8D7D1, dark: 0x3A3D3A)

    private static func adaptive(light: Int, dark: Int) -> Color {
        Color(nsColor: NSColor(name: nil) { appearance in
            let useDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            return rgb(useDark ? dark : light)
        })
    }

    private static func rgb(_ value: Int) -> NSColor {
        NSColor(srgbRed: CGFloat((value >> 16) & 0xFF) / 255,
                green: CGFloat((value >> 8) & 0xFF) / 255,
                blue: CGFloat(value & 0xFF) / 255,
                alpha: 1)
    }
}

struct RoomPanelModifier: ViewModifier {
    var tint: Color?

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(RoomPalette.surface)
                    .overlay {
                        if let tint {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(tint.opacity(0.045))
                        }
                    }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(RoomPalette.hairline, lineWidth: 1)
            }
    }
}

extension View {
    func roomPanel(tint: Color? = nil) -> some View {
        modifier(RoomPanelModifier(tint: tint))
    }
}

struct SectionHeader: View {
    let title: String
    var systemImage: String?
    var trailing: String?
    var accent: Color = .secondary

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(accent)
            }
            Text(title)
                .font(.body)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.body)
                    .monospacedDigit()
            }
        }
    }
}

struct RoomDivider: View {
    var body: some View {
        Rectangle()
            .fill(RoomPalette.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

struct EyebrowLabel: View {
    let title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(1.1)
            .foregroundStyle(.secondary)
    }
}

struct MetricCaption: View {
    let label: String
    let value: String
    var statusColor: Color?

    var body: some View {
        HStack(spacing: 5) {
            Text(label)
                .foregroundStyle(.secondary)
            if let statusColor {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)
            }
            Text(value)
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .font(.caption)
        .accessibilityElement(children: .combine)
    }
}

struct RoomEmptyState: View {
    let systemImage: String
    let title: String
    let detail: String
    var tint: Color = .accentColor

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2)
                .foregroundStyle(tint)
            Text(title)
                .font(.body.weight(.medium))
            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 21)
        .padding(.horizontal, 13)
        .roomPanel(tint: tint)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    var valueColor: Color = .primary

    var body: some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value).monospacedDigit().foregroundStyle(valueColor)
        }
        .font(.body)
        .accessibilityElement(children: .combine)
    }
}

/// Pressure row: color dot (●) + text in the normal color. The state text itself is not colored (design-system §3)
struct PressureRow: View {
    let pressure: MemoryPressureLevel

    var body: some View {
        HStack {
            Text("Pressure").foregroundStyle(.secondary)
            Spacer()
            HStack(spacing: 4) {
                Circle()
                    .fill(pressure.color)
                    .frame(width: 7, height: 7)
                Text(pressure.rawValue)
            }
        }
        .font(.body)
        .accessibilityElement(children: .combine)
    }
}

/// Usage bar (design-system §6). The numeric text is the authoritative information — the bar is a visual aid
struct UsageBar: View {
    let fraction: Double
    let tint: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(RoomPalette.subtleSurface)
                Capsule().fill(tint)
                    .frame(width: max(4, geo.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: 5)
        .accessibilityHidden(true)
    }
}

struct NavRow: View {
    let icon: Image
    let title: String
    var showsChevron = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                icon
                    .frame(width: 18)
                    .foregroundStyle(.secondary)
                Text(title)
                    .fontWeight(.medium)
                Spacer()
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
            .padding(.horizontal, 10)
            .padding(.vertical, 9)
            .background(RoomPalette.surface, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(RoomPalette.hairline, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

struct BackHeader: View {
    let title: String
    @Binding var route: PopoverRoute
    let back: PopoverRoute

    var body: some View {
        HStack(spacing: 8) {
            Button {
                route = back
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption.weight(.semibold))
                    .frame(width: 26, height: 26)
                    .background(RoomPalette.subtleSurface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Text(title)
                .font(.headline)
                .lineLimit(1)
            Spacer()
        }
        .frame(minHeight: 30)
    }
}

extension MemoryPressureLevel {
    /// Status color (design-system §3). Never rely on color alone (text is always shown alongside)
    var color: Color {
        switch self {
        case .normal: RoomPalette.memory
        case .warning: RoomPalette.warning
        case .critical: RoomPalette.critical
        case .unavailable: .secondary
        }
    }
}
