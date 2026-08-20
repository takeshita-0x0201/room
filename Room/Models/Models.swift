import Foundation

enum MemoryPressureLevel: String, Equatable, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
    case unavailable = "Unavailable"   // 取得失敗・未知値。Normal と区別する（要件 D21）
}

struct MemorySnapshot: Equatable {
    let totalBytes: UInt64
    let usedBytes: UInt64
    let swapUsedBytes: UInt64
    let pressure: MemoryPressureLevel

    var freeBytes: UInt64 { totalBytes > usedBytes ? totalBytes - usedBytes : 0 }
    var usedFraction: Double { totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) }
}

struct StorageSnapshot: Equatable {
    let totalBytes: UInt64
    let freeBytes: UInt64

    var usedBytes: UInt64 { totalBytes > freeBytes ? totalBytes - freeBytes : 0 }
    var usedFraction: Double { totalBytes == 0 ? 0 : Double(usedBytes) / Double(totalBytes) }
}

enum DisplayMode: String, CaseIterable {
    case percentage
    case free
    case used

    var title: String {
        switch self {
        case .percentage: "Percentage"
        case .free: "Free"
        case .used: "Used"
        }
    }
}
