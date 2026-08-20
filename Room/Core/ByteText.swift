import Foundation

/// The only numeric formatting implementation. RAM uses base 1024, storage base 1000 (requirements §6).
enum ByteText {
    enum ByteBase {
        case memory1024
        case storage1000

        var divisor: Double {
            switch self {
            case .memory1024: 1024
            case .storage1000: 1000
            }
        }
    }

    /// Common formatting for the numeric part: integers at 100+, one decimal below (.0 dropped)
    private static func scaledValue(_ value: Double) -> String {
        if value >= 99.95 { return String(Int(value.rounded())) }
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
    }

    /// "18.4" / "341" — GB value only (for the pair's GB display)
    static func gbValue(_ bytes: UInt64, base: ByteBase) -> String {
        scaledValue(Double(bytes) / pow(base.divisor, 3))
    }

    /// Menu bar short form: "824M" / "3.2G" / "171G" / "1.2T" (design-system §4)
    static func short(_ bytes: UInt64, base: ByteBase) -> String {
        let d = base.divisor
        let tb = Double(bytes) / pow(d, 4)
        if tb >= 0.9995 { return scaledValue(tb) + "T" }
        let gb = Double(bytes) / pow(d, 3)
        if gb >= 0.9995 { return scaledValue(gb) + "G" }
        let mb = Double(bytes) / pow(d, 2)
        return String(Int(mb.rounded())) + "M"
    }

    /// Popover detailed form: "824 MB" / "3.2 GB" / "171 GB" / "1.2 TB" (design-system §4)
    static func long(_ bytes: UInt64, base: ByteBase) -> String {
        let d = base.divisor
        let tb = Double(bytes) / pow(d, 4)
        if tb >= 0.9995 { return scaledValue(tb) + " TB" }
        let gb = Double(bytes) / pow(d, 3)
        if gb >= 0.9995 { return scaledValue(gb) + " GB" }
        let mb = Double(bytes) / pow(d, 2)
        return String(Int(mb.rounded())) + " MB"
    }

    /// "18.4 / 24 GB". Switches to TB units when total capacity is 1 TB or more
    static func pair(used: UInt64, total: UInt64, base: ByteBase) -> String {
        let d = base.divisor
        let tbDivisor = pow(d, 4)
        if Double(total) >= tbDivisor * 0.9995 {
            return "\(scaledValue(Double(used) / tbDivisor)) / \(scaledValue(Double(total) / tbDivisor)) TB"
        }
        return "\(gbValue(used, base: base)) / \(gbValue(total, base: base)) GB"
    }

    /// 0.72 → "72" (no % sign; the menu bar shows no units)
    static func percent(_ fraction: Double) -> String {
        String(Int((fraction * 100).rounded()))
    }
}
