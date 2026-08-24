import AppKit
import SwiftUI

enum RoomPalette {
    // System colors softened with gray so state remains familiar without looking overly saturated.
    static let memory = muted(.systemBlue, amount: 0.22)
    static let storage = muted(.systemGreen, amount: 0.22)
    static let warning = muted(.systemYellow, amount: 0.18)
    static let critical = muted(.systemRed, amount: 0.18)
    static let canvas = Color(nsColor: .windowBackgroundColor)
    static let subtleSurface = Color.primary.opacity(0.045)
    static let hairline = Color.primary.opacity(0.09)

    private static func muted(_ color: NSColor, amount: CGFloat) -> Color {
        Color(nsColor: color.blended(withFraction: amount, of: .systemGray) ?? color)
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
        .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 13))
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
                Capsule().fill(.quaternary)
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
            .background(RoomPalette.subtleSurface, in: RoundedRectangle(cornerRadius: 9))
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
