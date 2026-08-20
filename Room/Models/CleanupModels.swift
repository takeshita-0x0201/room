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
    let minFileAge: TimeInterval?          // nil = 全件対象
    let blockingBundleIDs: [String]        // 実行中ならこの項目をブロック（要件 §18.4）
    let requiresFullDiskAccess: Bool
    let isGenericCachesScan: Bool          // ~/Library/Caches の汎用スキャン（唯一）
}

/// スキャン時に確定した削除対象 1 ディレクトリ。inode / device を記録し、
/// 削除直前に同一性を再検証する（要件 §18.5 / D19: TOCTOU・symlink 差し替え対策）
struct CleanupTarget: Equatable {
    let url: URL
    let fileNumber: Int      // inode
    let deviceNumber: Int
}

/// 削除時の許可ルート・age・ブロッカーは item ではなく CleanupService が
/// 自身の rules から ID で再導出する（多層防御 — item 側の値は安全境界ではない）。
struct CleanupItem: Identifiable, Equatable {
    enum State: Equatable {
        case ready
        case blocked(runningApp: String)
        case needsFullDiskAccess
    }

    let id: String
    let title: String
    let summaryGroup: CleanupSummaryGroup
    let targets: [CleanupTarget]           // 「この中身を消す」対象ディレクトリ群
    let sizeBytes: UInt64
    let state: State
}

struct CleanupOutcome: Equatable {
    let deletedBytes: UInt64       // 実際に削除したファイルサイズ合計。成果表示はこれ（要件 D22）
    let skippedPaths: [String]
    let freeBefore: UInt64         // 参考値。APFS の空き容量反映は遅延するため成果表示に使わない
    let freeAfter: UInt64
}