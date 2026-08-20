import AppKit

protocol QuitServicing {
    func requestQuit(_ group: ProcessGroup)
    func forceQuit(_ group: ProcessGroup)
    func isRunning(_ group: ProcessGroup) -> Bool
}

/// Quit is a "request". The app can block it with an unsaved-changes prompt (the §14.3 follow-up UI lives on the View side).
/// Defense in depth (requirements §14.4 / D23):
/// - The service layer re-checks the protection policy (doesn't rely only on UI disabled state)
/// - For .app groups, resolve the running app by bundle URL match before acting (safe against PID reuse)
/// - For non-app processes, verify the executable path identity and signal only the validated mainPid
final class QuitService: QuitServicing {
    private let policy: ProcessProtectionPolicy

    init(policy: ProcessProtectionPolicy = ProcessProtectionPolicy(
            currentUid: getuid(),
            ownPid: ProcessInfo.processInfo.processIdentifier)) {
        self.policy = policy
    }

    func requestQuit(_ group: ProcessGroup) {
        guard policy.canQuit(group) else { return }
        if group.bundlePath != nil {
            runningApplication(for: group)?.terminate()   // standard graceful-termination flow
        } else if isSameProcess(group) {
            kill(group.mainPid, SIGTERM)
        }
    }

    func forceQuit(_ group: ProcessGroup) {
        guard policy.canQuit(group) else { return }
        if group.bundlePath != nil {
            runningApplication(for: group)?.forceTerminate()
        } else if isSameProcess(group) {
            kill(group.mainPid, SIGKILL)
        }
    }

    func isRunning(_ group: ProcessGroup) -> Bool {
        if let bundlePath = group.bundlePath {
            // A Helper left behind after the main process exits still counts as "running" (requirements §14.3).
            // Requiring the path to be under the bundle also makes this safe against PID reuse.
            return group.pids.contains { pid in
                kill(pid, 0) == 0
                    && ProcessService.path(of: pid)?.hasPrefix(bundlePath + "/") == true
            }
        }
        return isSameProcess(group) && kill(group.mainPid, 0) == 0
    }

    /// Resolves the operation target for a .app group. If mainPid matches the bundle, use it;
    /// otherwise (when rusage/path fetch for main failed and a Helper became mainPid) find the
    /// running app by bundle URL. If unresolvable, nil = do nothing (the safe side).
    private func runningApplication(for group: ProcessGroup) -> NSRunningApplication? {
        guard let bundlePath = group.bundlePath else { return nil }
        if let app = NSRunningApplication(processIdentifier: group.mainPid),
           app.bundleURL?.path == bundlePath {
            return app
        }
        return NSWorkspace.shared.runningApplications.first { $0.bundleURL?.path == bundlePath }
    }

    /// Non-app process: true only when mainPid's executable path matches the recorded one.
    /// Falls back to the safe side (false) when it cannot be verified.
    private func isSameProcess(_ group: ProcessGroup) -> Bool {
        guard let recorded = group.mainPath else { return false }
        return ProcessService.path(of: group.mainPid) == recorded
    }
}
