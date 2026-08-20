import Foundation

/// Re-verification right before deletion (requirements §18.5 / D19). Never delete scan results without verification.
enum CleanupTargetVerifier {
    /// Returns nil for a symlink; otherwise a CleanupTarget recording inode / device.
    /// attributesOfItem is lstat-equivalent and does not follow links.
    static func makeTarget(_ url: URL, fileManager fm: FileManager) -> CleanupTarget? {
        guard let attrs = try? fm.attributesOfItem(atPath: url.path),
              (attrs[.type] as? FileAttributeType) != .typeSymbolicLink,
              let fileNumber = attrs[.systemFileNumber] as? Int,
              let deviceNumber = attrs[.systemNumber] as? Int
        else { return nil }
        return CleanupTarget(url: url, fileNumber: fileNumber, deviceNumber: deviceNumber)
    }

    /// Whether it is still the same file entity as at scan time (not swapped, deleted, or symlinked)
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
