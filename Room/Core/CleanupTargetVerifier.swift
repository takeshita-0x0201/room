import Foundation

/// 削除直前の再検証（要件 §18.5 / D19）。スキャン結果を無検証で消さない。
enum CleanupTargetVerifier {
    /// symlink なら nil。それ以外は inode / device を記録した CleanupTarget を返す。
    /// attributesOfItem は lstat 相当でリンクを辿らない。
    static func makeTarget(_ url: URL, fileManager fm: FileManager) -> CleanupTarget? {
        guard let attrs = try? fm.attributesOfItem(atPath: url.path),
              (attrs[.type] as? FileAttributeType) != .typeSymbolicLink,
              let fileNumber = attrs[.systemFileNumber] as? Int,
              let deviceNumber = attrs[.systemNumber] as? Int
        else { return nil }
        return CleanupTarget(url: url, fileNumber: fileNumber, deviceNumber: deviceNumber)
    }

    /// スキャン時と同一のファイル実体か（差し替え・削除・symlink 化されていないか）
    static func isUnchanged(_ target: CleanupTarget, fileManager fm: FileManager) -> Bool {
        guard let current = makeTarget(target.url, fileManager: fm) else { return false }
        return current == target
    }

    static func isUnder(_ url: URL, roots: [URL]) -> Bool {
        let path = url.standardizedFileURL.path
        return roots.contains { root in
            let rootPath = root.standardizedFileURL.path
            return path == rootPath || path.hasPrefix(rootPath + "/")
        }
    }
}
