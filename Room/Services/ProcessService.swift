import Foundation

protocol ProcessListProviding {
    func groups() -> [ProcessGroup]
}

/// libproc / sysctl call layer. Returns only processes owned by the current user (requirements §6.3).
final class ProcessService: ProcessListProviding {
    func groups() -> [ProcessGroup] {
        ProcessAggregator.aggregate(rawProcesses())
    }

    private func rawProcesses() -> [RawProcess] {
        let currentUid = getuid()
        return Self.allPids().compactMap { pid in
            guard let owner = Self.uid(of: pid), owner == currentUid else { return nil }
            guard let footprint = Self.footprint(of: pid), footprint > 0 else { return nil }
            let path = Self.path(of: pid)
            let name = Self.name(of: pid)
                ?? path.map { ($0 as NSString).lastPathComponent }
                ?? "pid \(pid)"
            return RawProcess(pid: pid, name: name, path: path,
                              footprintBytes: footprint, uid: owner)
        }
    }

    static func allPids() -> [pid_t] {
        let estimated = proc_listallpids(nil, 0)   // return value is the pid count
        guard estimated > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimated) + 64)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard count > 0 else { return [] }
        return Array(pids.prefix(Int(count))).filter { $0 > 0 }
    }

    /// ri_phys_footprint (the same metric as Activity Monitor's "Memory" column)
    static func footprint(of pid: pid_t) -> UInt64? {
        var info = rusage_info_current()
        let ok = withUnsafeMutablePointer(to: &info) { pointer -> Bool in
            pointer.withMemoryRebound(to: (rusage_info_t?).self, capacity: 1) {
                proc_pid_rusage(pid, RUSAGE_INFO_CURRENT, $0) == 0
            }
        }
        return ok ? info.ri_phys_footprint : nil
    }

    static func path(of pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: 4 * Int(MAXPATHLEN))
        let length = proc_pidpath(pid, &buffer, UInt32(buffer.count))
        return length > 0 ? String(cString: buffer) : nil
    }

    static func name(of pid: pid_t) -> String? {
        var buffer = [CChar](repeating: 0, count: Int(MAXPATHLEN))
        let length = proc_name(pid, &buffer, UInt32(buffer.count))
        return length > 0 ? String(cString: buffer) : nil
    }

    static func uid(of pid: pid_t) -> uid_t? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, 4, &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return info.kp_eproc.e_ucred.cr_uid
    }
}
