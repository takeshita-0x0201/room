import SwiftUI

struct SectionHeader: View {
    let title: String
    var systemImage: String?
    var trailing: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 5) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            Text(title)
                .font(.subheadline.weight(.bold))
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.headline)
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
        .font(.callout)
        .accessibilityElement(children: .combine)
    }
}

/// 使用率バー（design-system §6）。数値テキストが情報の正 — バーは視覚補助
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
    /// 状態色（design-system §3）。色だけで伝えない（テキスト併記が前提）
    var color: Color {
        switch self {
        case .normal: .blue
        case .warning: .yellow
        case .critical: .red
        case .unavailable: .secondary
        }
    }
}
