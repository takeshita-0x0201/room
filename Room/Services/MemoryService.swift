import Foundation

protocol MemoryStatsProviding {
    func snapshot() -> MemorySnapshot?
}

/// mach / sysctl 呼び出しはこのファイルに閉じ込める（View やロジックから直接呼ばない）
final class MemoryService: MemoryStatsProviding {
    func snapshot() -> MemorySnapshot? {
        guard let raw = Self.readVMStats() else { return nil }
        return MemorySnapshot(
            totalBytes: ProcessInfo.processInfo.physicalMemory,
            usedBytes: MemoryMath.usedBytes(raw),
            swapUsedBytes: Self.readSwapUsed() ?? 0,
            pressure: Self.readPressureLevel()
        )
    }

    static func readVMStats() -> RawMemoryStats? {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(
            MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        return RawMemoryStats(
            internalPages: UInt64(stats.internal_page_count),
            purgeablePages: UInt64(stats.purgeable_count),
            wiredPages: UInt64(stats.wire_count),
            compressorPages: UInt64(stats.compressor_page_count),
            pageSize: UInt64(pageSize)
        )
    }

    static func readSwapUsed() -> UInt64? {
        var usage = xsw_usage()
        var size = MemoryLayout<xsw_usage>.size
        guard sysctlbyname("vm.swapusage", &usage, &size, nil, 0) == 0 else { return nil }
        return UInt64(usage.xsu_used)
    }

    static func readPressureLevel() -> MemoryPressureLevel {
        var level: Int32 = 0
        var size = MemoryLayout<Int32>.size
        guard sysctlbyname("kern.memorystatus_vm_pressure_level", &level, &size, nil, 0) == 0 else {
            return .unavailable
        }
        return MemoryMath.pressureLevel(fromSysctl: level)
    }
}
