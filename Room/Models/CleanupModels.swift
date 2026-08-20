import Foundation

enum CleanupSummaryGroup: String, CaseIterable {
    case caches = "Caches"
    case developer = "Developer"
    case logs = "Logs"
    case trash = "Trash"
}

struct CleanupRule: Identifiable {
    let id: String
    let title: String
    let summaryGroup: CleanupSummaryGroup
    let roots: [URL]
    let minFileAge: TimeInterval?          // nil = all items in scope
    let blockingBundleIDs: [String]        // blocks this item while running (requirements §18.4)
    let requiresFullDiskAccess: Bool
    let isGenericCachesScan: Bool          // generic ~/Library/Caches scan (the only one)
}

/// One directory fixed as a deletion target at scan time. Records inode / device and
/// re-verifies identity right before deletion (requirements §18.5 / D19: TOCTOU and symlink-swap protection)
struct CleanupTarget: Equatable {
    let url: URL
    let fileNumber: Int      // inode
    let deviceNumber: Int
}

/// Allowed roots, age, and blockers at deletion time are re-derived by ID from CleanupService's
/// own rules, not from the item (defense in depth — item-side values are not a safety boundary).
struct CleanupItem: Identifiable, Equatable {
    enum State: Equatable {
        case ready
        case blocked(runningApp: String)
        case needsFullDiskAccess
    }

    let id: String
    let title: String
    let summaryGroup: CleanupSummaryGroup
    let targets: [CleanupTarget]           // directories whose contents are to be deleted
    let sizeBytes: UInt64
    let state: State
}

struct CleanupOutcome: Equatable {
    let deletedBytes: UInt64       // total size actually deleted. This drives the result display (requirements D22)
    let skippedPaths: [String]
    let freeBefore: UInt64         // reference only. APFS free-space updates are delayed, so not used for the result display
    let freeAfter: UInt64
}