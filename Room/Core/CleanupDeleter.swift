import Foundation

enum CleanupDeleter {
    struct Result {
        var deletedBytes: UInt64 = 0
        var skippedPaths: [String] = []
    }

    /// Deletes the "contents" of root; root itself is kept (requirements §18.5).
    /// With an age, only old regular files are deleted and the directory structure is kept.
    /// Errors skip that item and continue (requirements §18.6).
    static func deleteContents(of root: URL, olderThan age: TimeInterval?,
                               now: Date, fileManager fm: FileManager) -> Result {
        var result = Result()
        if let age {
            let keys: [URLResourceKey] =
                [.isRegularFileKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]
            guard let enumerator = fm.enumerator(
                at: root, includingPropertiesForKeys: keys,
                options: [], errorHandler: { _, _ in true }) else { return result }
            let files = enumerator.compactMap { $0 as? URL }
            for url in files {
                guard let values = try? url.resourceValues(forKeys: Set(keys)),
                      values.isRegularFile == true,
                      let modified = values.contentModificationDate,
                      now.timeIntervalSince(modified) > age else { continue }
                let size = UInt64(values.totalFileAllocatedSize ?? 0)
                do {
                    try fm.removeItem(at: url)
                    result.deletedBytes += size
                } catch {
                    result.skippedPaths.append(url.path)
                }
            }
        } else {
            let children = (try? fm.contentsOfDirectory(
                at: root, includingPropertiesForKeys: nil)) ?? []
            for child in children {
                let size = DirectorySizer.size(of: child, olderThan: nil)
                do {
                    try fm.removeItem(at: child)
                    result.deletedBytes += size
                } catch {
                    result.skippedPaths.append(child.path)
                }
            }
        }
        return result
    }
}
