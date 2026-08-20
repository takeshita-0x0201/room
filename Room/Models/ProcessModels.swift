import Foundation

struct RawProcess: Equatable {
    let pid: pid_t
    let name: String
    let path: String?
    let footprintBytes: UInt64
    let uid: uid_t
}

struct ProcessGroup: Identifiable, Equatable {
    let id: String              // bundlePath or "pid:<pid>"
    let displayName: String
    let bundlePath: String?     // ".../Google Chrome.app" (only for .app groups)
    let mainPath: String?
    let mainPid: pid_t
    let pids: [pid_t]
    let footprintBytes: UInt64
    let uid: uid_t
}
