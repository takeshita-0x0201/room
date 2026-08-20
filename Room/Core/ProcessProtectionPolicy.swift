import Foundation

/// Quit / Force Quit 可否の判定（要件 §15）。緩和禁止。
struct ProcessProtectionPolicy {
    static let deniedNames: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "loginwindow", "Dock",
        "SystemUIServer", "ControlCenter", "NotificationCenter", "Spotlight",
        "coreaudiod", "mds", "mds_stores", "logd", "launchservicesd",
        "distnoted", "cfprefsd",
    ]
    static let allowedSystemApps: Set<String> = ["Finder"]  // 終了しても OS が自動再起動する

    let currentUid: uid_t
    let ownPid: pid_t

    func canQuit(_ group: ProcessGroup) -> Bool {
        if group.pids.contains(where: { $0 <= 1 }) { return false }
        if group.pids.contains(ownPid) { return false }
        if group.uid != currentUid { return false }
        if Self.deniedNames.contains(group.displayName) { return false }
        if let path = group.mainPath,
           path.hasPrefix("/System/Library/CoreServices"),
           !Self.allowedSystemApps.contains(group.displayName) {
            return false
        }
        return true
    }
}
