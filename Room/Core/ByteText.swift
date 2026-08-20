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

    /// "18.4" / "341" — GB 数値のみ。100 以上は整数、未満は小数 1 桁（.0 は落とす）
    static func gbValue(_ bytes: UInt64, base: ByteBase) -> String {
        let gb = Double(bytes) / pow(base.divisor, 3)
        if gb >= 99.95 { return String(Int(gb.rounded())) }
        let rounded = (gb * 10).rounded() / 10
        return rounded == rounded.rounded()
            ? String(Int(rounded))
            : String(format: "%.1f", rounded)
    }

    /// メニューバー用短縮形: "5.6G" / "171G" / "768M"
    static func short(_ bytes: UInt64, base: ByteBase) -> String {
        let gb = Double(bytes) / pow(base.divisor, 3)
        if gb >= 0.9995 { return gbValue(bytes, base: base) + "G" }
        let mb = Double(bytes) / pow(base.divisor, 2)
        return String(Int(mb.rounded())) + "M"
    }

    /// Popover 用長形式: "18.4 GB" / "768 MB"
    static func long(_ bytes: UInt64, base: ByteBase) -> String {
        let gb = Double(bytes) / pow(base.divisor, 3)
        if gb >= 0.9995 { return gbValue(bytes, base: base) + " GB" }
        let mb = Double(bytes) / pow(base.divisor, 2)
        return String(Int(mb.rounded())) + " MB"
    }

    /// "18.4 / 24 GB"
    static func pair(used: UInt64, total: UInt64, base: ByteBase) -> String {
        "\(gbValue(used, base: base)) / \(gbValue(total, base: base)) GB"
    }

    /// 0.72 → "72"（% 記号は付けない。メニューバーで単位を出さないため）
    static func percent(_ fraction: Double) -> String {
        String(Int((fraction * 100).rounded()))
    }
}
