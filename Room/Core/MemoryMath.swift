import Foundation

struct RawMemoryStats: Equatable {
    let internalPages: UInt64
    let purgeablePages: UInt64
    let wiredPages: UInt64
    let compressorPages: UInt64
    let pageSize: UInt64
}

enum MemoryMath {
    /// Approximation of Activity Monitor's "Memory Used" (App + Wired + Compressed).
    /// Clamping happens at the App Memory = internal − purgeable step (requirements D3)
    static func usedBytes(_ stats: RawMemoryStats) -> UInt64 {
        let appPages = stats.internalPages > stats.purgeablePages
            ? stats.internalPages - stats.purgeablePages : 0
        return (appPages + stats.wiredPages + stats.compressorPages) * stats.pageSize
    }

    /// kern.memorystatus_vm_pressure_level: 1=Normal, 2=Warning, 4=Critical.
    /// Anything else (including a failed read) is Unavailable — never fall back to Normal (requirements D21)
    static func pressureLevel(fromSysctl value: Int32) -> MemoryPressureLevel {
        switch value {
        case 1: .normal
        case 2: .warning
        case 4: .critical
        default: .unavailable
        }
    }
}
