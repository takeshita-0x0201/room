import Foundation

/// メニューバーに出す数値文字列（アイコンは View 側）。単位・% 記号は出さない（要件 §7）。
enum MenuBarText {
    static func memoryValue(_ snapshot: MemorySnapshot?, mode: DisplayMode) -> String {
        guard let s = snapshot else { return "–" }
        switch mode {
        case .percentage: return ByteText.percent(s.usedFraction)
        case .free: return ByteText.short(s.freeBytes, base: .memory1024)
        case .used: return ByteText.short(s.usedBytes, base: .memory1024)
        }
    }

    static func storageValue(_ snapshot: StorageSnapshot?, mode: DisplayMode) -> String {
        guard let s = snapshot else { return "–" }
        switch mode {
        case .percentage: return ByteText.percent(s.usedFraction)
        case .free: return ByteText.short(s.freeBytes, base: .storage1000)
        case .used: return ByteText.short(s.usedBytes, base: .storage1000)
        }
    }
}
