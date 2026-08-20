import AppKit

protocol QuitServicing {
    func requestQuit(_ group: ProcessGroup)
    func forceQuit(_ group: ProcessGroup)
    func isRunning(_ group: ProcessGroup) -> Bool
}

/// Quit は「要求」。アプリ側の未保存確認でブロックされ得る（要件 §14.3 のフォロー UI は View 側）。
/// 多層防御（要件 §14.4 / D23）:
/// - サービス層でも保護ポリシーを再判定する（UI の disabled だけに依存しない）
/// - .app グループは bundle URL 一致で実行中アプリを解決してから操作する（PID 再利用に安全）
/// - 非アプリプロセスは実行パスの同一性を確認し、検証済みの mainPid にのみシグナルを送る
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
            runningApplication(for: group)?.terminate()   // 標準の正常終了フロー
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
            // メイン終了後に Helper が残るケースも「実行中」と判定する（要件 §14.3）。
            // パスが bundle 配下であることを要求するので PID 再利用にも安全。
            return group.pids.contains { pid in
                kill(pid, 0) == 0
                    && ProcessService.path(of: pid)?.hasPrefix(bundlePath + "/") == true
            }
        }
        return isSameProcess(group) && kill(group.mainPid, 0) == 0
    }

    /// .app グループの操作対象を解決する。mainPid が bundle と一致すればそれを、
    /// 一致しない場合（main の rusage/path 取得失敗で Helper が mainPid になったケース）は
    /// bundle URL 一致で実行中アプリを探す。解決できなければ nil = 何もしない（安全側）。
    private func runningApplication(for group: ProcessGroup) -> NSRunningApplication? {
        guard let bundlePath = group.bundlePath else { return nil }
        if let app = NSRunningApplication(processIdentifier: group.mainPid),
           app.bundleURL?.path == bundlePath {
            return app
        }
        return NSWorkspace.shared.runningApplications.first { $0.bundleURL?.path == bundlePath }
    }

    /// 非アプリプロセス: mainPid の実行パスが記録時と一致するときのみ true。
    /// 検証できない場合は安全側に倒して false。
    private func isSameProcess(_ group: ProcessGroup) -> Bool {
        guard let recorded = group.mainPath else { return false }
        return ProcessService.path(of: group.mainPid) == recorded
    }
}
