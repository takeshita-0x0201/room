import Foundation

enum CleanupPlanner {
    /// Decides the generic scan targets directly under ~/Library/Caches (requirements §18.3 exclusivity rules):
    /// - com.apple.* is excluded (only paths claimed by an explicit rule are handled)
    /// - anything that is not a reverse-DNS name (2+ dots) is excluded — "Google" etc. cannot be resolved as running (requirements D20)
    /// - directories matching a running app's bundle id are excluded (requirements §18.4)
    /// - paths claimed by other rules (descendant or ancestor) are excluded — prevents double counting and collateral deletion
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