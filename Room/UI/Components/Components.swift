import SwiftUI

struct SectionHeader: View {
    let title: String
    var systemImage: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.body)
                    .foregroundStyle(.secondary)
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
            HStack {
                icon.frame(width: 16)
                Text(title)
                Spacer()
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct BackHeader: View {
    let title: String
    @Binding var route: PopoverRoute
    let back: PopoverRoute

    var body: some View {
        HStack(spacing: 6) {
            Button {
                route = back
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Back")
            Text(title).font(.headline)
            Spacer()
        }
    }
}

extension MemoryPressureLevel {
    /// Status color (design-system §3). Never rely on color alone (text is always shown alongside)
    var color: Color {
        switch self {
        case .normal: .blue
        case .warning: .yellow
        case .critical: .red
        case .unavailable: .secondary
        }
    }
}
