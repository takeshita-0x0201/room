import Foundation

enum DirectorySizer {
    private static let keys: Set<URLResourceKey> =
        [.isRegularFileKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]

    /// url 配下（url 自身がファイルならそれ）の実割当サイズ合計。
    /// age 指定時は「最終更新が age より古い通常ファイル」のみ数える。
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
