import Foundation

/// Decides whether Quit / Force Quit is allowed (requirements §15). Must not be relaxed.
struct ProcessProtectionPolicy {
    static let deniedNames: Set<String> = [
        "kernel_task", "launchd", "WindowServer", "loginwindow", "Dock",
        "SystemUIServer", "ControlCenter", "NotificationCenter", "Spotlight",
        "coreaudiod", "mds", "mds_stores", "logd", "launchservicesd",
        "distnoted", "cfprefsd",
    ]
    static let allowedSystemApps: Set<String> = ["Finder"]  // the OS restarts it automatically even if terminated

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
