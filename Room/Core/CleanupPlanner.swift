import Foundation

enum CleanupPlanner {
    /// ~/Library/Caches 直下の汎用スキャン対象を決める（要件 §18.3 排他ルール）:
    /// - com.apple.* は除外（明示ルールで claim されたものだけ扱う）
    /// - reverse-DNS 名（ドット 2 個以上）以外は除外 — "Google" 等は実行中判定不能（要件 D20）
    /// - 実行中アプリの bundle id と一致するディレクトリは除外（要件 §18.4）
    /// - 他ルールが claim したパス（子孫 or 祖先）は除外 → 二重計上・巻き添え削除の防止
    static func genericCacheChildren(allChildren: [URL],
                                     claimedRoots: [URL],
                                     runningBundleIDs: Set<String>) -> [URL] {
        let claimedPaths = claimedRoots.map { $0.standardizedFileURL.path }
        return allChildren.filter { child in
            let name = child.lastPathComponent
            if name.hasPrefix("com.apple.") { return false }
            if name.split(separator: ".").count < 3 { return false }
            if runningBundleIDs.contains(name) { return false }
            let path = child.standardizedFileURL.path
            let overlapsClaimed = claimedPaths.contains { claimed in
                path == claimed
                    || path.hasPrefix(claimed + "/")
                    || claimed.hasPrefix(path + "/")
            }
            return !overlapsClaimed
        }
    }
}

enum CleanupSummary {
    static func totals(_ items: [CleanupItem]) -> [CleanupSummaryGroup: UInt64] {
        items.reduce(into: [:]) { result, item in
            result[item.summaryGroup, default: 0] += item.sizeBytes
        }
    }

    static func grandTotal(_ items: [CleanupItem]) -> UInt64 {
        items.reduce(0) { $0 + $1.sizeBytes }
    }
}