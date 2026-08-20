import Foundation

/// 数値フォーマットの唯一の実装。RAM は 1024 基数、ストレージは 1000 基数（要件 §6）。
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

    /// 数値部の共通整形: 100 以上は整数、未満は小数 1 桁（.0 は落とす）
    private static func scaledValue(_ value: Double) -> String {
        if value >= 99.95 { return String(Int(value.rounded())) }
        let rounded = (value * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
    }

    /// "18.4" / "341" — GB 数値のみ（pair の GB 表示用）
    static func gbValue(_ bytes: UInt64, base: ByteBase) -> String {
        scaledValue(Double(bytes) / pow(base.divisor, 3))
    }

    /// メニューバー用短縮形: "824M" / "3.2G" / "171G" / "1.2T"（design-system §4）
    static func short(_ bytes: UInt64, base: ByteBase) -> String {
        let d = base.divisor
        let tb = Double(bytes) / pow(d, 4)
        if tb >= 0.9995 { return scaledValue(tb) + "T" }
        let gb = Double(bytes) / pow(d, 3)
        if gb >= 0.9995 { return scaledValue(gb) + "G" }
        let mb = Double(bytes) / pow(d, 2)
        return String(Int(mb.rounded())) + "M"
    }

    /// Popover 用詳細形: "824 MB" / "3.2 GB" / "171 GB" / "1.2 TB"（design-system §4）
    static func long(_ bytes: UInt64, base: ByteBase) -> String {
        let d = base.divisor
        let tb = Double(bytes) / pow(d, 4)
        if tb >= 0.9995 { return scaledValue(tb) + " TB" }
        let gb = Double(bytes) / pow(d, 3)
        if gb >= 0.9995 { return scaledValue(gb) + " GB" }
        let mb = Double(bytes) / pow(d, 2)
        return String(Int(mb.rounded())) + " MB"
    }

    /// "18.4 / 24 GB"。総容量が 1TB 以上なら TB 単位に切り替える
    static func pair(used: UInt64, total: UInt64, base: ByteBase) -> String {
        let d = base.divisor
        let tbDivisor = pow(d, 4)
        if Double(total) >= tbDivisor * 0.9995 {
            return "\(scaledValue(Double(used) / tbDivisor)) / \(scaledValue(Double(total) / tbDivisor)) TB"
        }
        return "\(gbValue(used, base: base)) / \(gbValue(total, base: base)) GB"
    }

    /// 0.72 → "72"（% 記号は付けない。メニューバーで単位を出さないため）
    static func percent(_ fraction: Double) -> String {
        String(Int((fraction * 100).rounded()))
    }
}
