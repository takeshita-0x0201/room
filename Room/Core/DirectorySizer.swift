import Foundation

enum DirectorySizer {
    private static let keys: Set<URLResourceKey> =
        [.isRegularFileKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]

    /// Total allocated size under url (or of url itself if it is a file).
    /// With an age, only regular files whose last modification is older than age are counted.
    static func size(of url: URL, olderThan age: TimeInterval?, now: Date = Date()) -> UInt64 {
        if let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true {
            return countedSize(values, age: age, now: now)
        }
        guard let enumerator = FileManager.default.enumerator(
            at: url, includingPropertiesForKeys: Array(keys),
            options: [], errorHandler: { _, _ in true }) else { return 0 }
        var total: UInt64 = 0
        for case let fileURL as URL in enumerator {
            if Task.isCancelled { return total }
            guard let values = try? fileURL.resourceValues(forKeys: keys) else { continue }
            total += countedSize(values, age: age, now: now)
        }
        return total
    }

    private static func countedSize(_ values: URLResourceValues,
                                    age: TimeInterval?, now: Date) -> UInt64 {
        guard values.isRegularFile == true else { return 0 }
        if let age {
            guard let modified = values.contentModificationDate,
                  now.timeIntervalSince(modified) > age else { return 0 }
        }
        return UInt64(values.totalFileAllocatedSize ?? 0)
    }
}
