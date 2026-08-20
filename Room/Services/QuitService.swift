import AppKit

protocol QuitServicing {
    func requestQuit(_ group: ProcessGroup)
    func forceQuit(_ group: ProcessGroup)
    func isRunning(_ group: ProcessGroup) -> Bool
}

/// Quit は「要求」。アプリ側の未保存確認でブロックされ得る（要件 §14.3 のフォロー UI は View 側）。
/// 多層防御（要件 §14.4 / D23）:
/// - サービス層でも保護ポリシーを再判定する（UI の disabled だけに依存しない）
/// - PID 再利用対策として、操作直前に実行パスの同一性を確認する
final class QuitService: QuitServicing {
    private let policy: ProcessProtectionPolicy

    init(policy: ProcessProtectionPolicy = ProcessProtectionPolicy(
            currentUid: getuid(),
            ownPid: ProcessInfo.processInfo.processIdentifier)) {
        self.policy = policy
    }

    func requestQuit(_ group: ProcessGroup) {
        guard policy.canQuit(group), isSameProcess(group) else { return }
        if group.bundlePath != nil {
            if let app = NSRunningApplication(processIdentifier: group.mainPid),
               app.bundleURL?.path == group.bundlePath {
                app.terminate()      // 標準の正常終了フロー（kAEQuitApplication）
            }
        } else {
            group.pids.forEach { kill($0, SIGTERM) }
        }
    }

    func forceQuit(_ group: ProcessGroup) {
        guard policy.canQuit(group), isSameProcess(group) else { return }
        if group.bundlePath != nil {
            if let app = NSRunningApplication(processIdentifier: group.mainPid),
               app.bundleURL?.path == group.bundlePath {
                app.forceTerminate()
            }
        } else {
            group.pids.forEach { kill($0, SIGKILL) }
        }
    }

    func isRunning(_ group: ProcessGroup) -> Bool {
        isSameProcess(group) && kill(group.mainPid, 0) == 0
    }

    /// mainPid の実行パスが記録時と一致するときのみ true。
    /// 検証できない（パス未記録・取得失敗 = 別プロセスに再利用された可能性）場合は安全側に倒して false。
    private func isSameProcess(_ group: ProcessGroup) -> Bool {
        guard let recorded = group.mainPath else { return false }
        return ProcessService.path(of: group.mainPid) == recorded
    }
}
