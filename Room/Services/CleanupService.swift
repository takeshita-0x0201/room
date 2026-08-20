import AppKit

protocol CleanupScanning {
    func scan() async -> [CleanupItem]
}

protocol CleanupDeleting {
    func delete(_ items: [CleanupItem]) async -> CleanupOutcome
}

struct RunningApp {
    let bundleID: String
    let name: String
}

final class CleanupService: CleanupScanning, CleanupDeleting {
    private let rules: [CleanupRule]
    private let storage: StorageStatsProviding
    private let runningApps: () -> [RunningApp]

    init(rules: [CleanupRule] = CleanupRules.standard(
            home: FileManager.default.homeDirectoryForCurrentUser,
            tmpDir: URL(fileURLWithPath: NSTemporaryDirectory())),
         storage: StorageStatsProviding = StorageService(),
         runningApps: @escaping () -> [RunningApp] = {
            NSWorkspace.shared.runningApplications.compactMap { app in
                app.bundleIdentifier.map {
                    RunningApp(bundleID: $0, name: app.localizedName ?? $0)
                }
            }
         }) {
        self.rules = rules
        self.storage = storage
        self.runningApps = runningApps
    }

    func scan() async -> [CleanupItem] {
        let running = runningApps()
        let runningIDs = Set(running.map(\.bundleID))
        let fm = FileManager.default
        var items: [CleanupItem] = []

        for rule in rules {
            if Task.isCancelled { break }

            if rule.requiresFullDiskAccess, let root = rule.roots.first {
                // 読めない = FDA 未付与（要件 §5: 先回りして要求せず、行として案内する）
                if (try? fm.contentsOfDirectory(atPath: root.path)) == nil {
                    items.append(CleanupItem(
                        id: rule.id, title: rule.title, summaryGroup: rule.summaryGroup,
                        targets: [], allowedRoots: rule.roots, blockingBundleIDs: [],
                        minFileAge: nil, sizeBytes: 0,
                        state: .needsFullDiskAccess))
                    continue
                }
            }

            var targetURLs = rule.roots.filter { fm.fileExists(atPath: $0.path) }
            if rule.isGenericCachesScan, let cachesRoot = rule.roots.first {
                let children = (try? fm.contentsOfDirectory(
                    at: cachesRoot, includingPropertiesForKeys: nil)) ?? []
                let claimed = rules.filter { $0.id != rule.id }.flatMap(\.roots)
                targetURLs = CleanupPlanner.genericCacheChildren(
                    allChildren: children, claimedRoots: claimed,
                    runningBundleIDs: runningIDs)
            }
            // symlink は makeTarget が nil を返すのでここで対象から外れる（要件 D19）
            let targets = targetURLs.compactMap {
                CleanupTargetVerifier.makeTarget($0, fileManager: fm)
            }
            guard !targets.isEmpty else { continue }

            let size = targets.reduce(UInt64(0)) {
                $0 + DirectorySizer.size(of: $1.url, olderThan: rule.minFileAge)
            }
            guard size > 0 else { continue }

            let state: CleanupItem.State
            if let blocker = running.first(where: { rule.blockingBundleIDs.contains($0.bundleID) }) {
                state = .blocked(runningApp: blocker.name)
            } else {
                state = .ready
            }
            items.append(CleanupItem(
                id: rule.id, title: rule.title, summaryGroup: rule.summaryGroup,
                targets: targets, allowedRoots: rule.roots,
                blockingBundleIDs: rule.blockingBundleIDs,
                minFileAge: rule.minFileAge,
                sizeBytes: size, state: state))
        }
        return items
    }

    func delete(_ items: [CleanupItem]) async -> CleanupOutcome {
        let freeBefore = storage.snapshot()?.freeBytes ?? 0
        var deleted: UInt64 = 0
        var skipped: [String] = []
        let now = Date()
        let fm = FileManager.default
        // スキャン後に対象アプリが起動された可能性があるため、削除直前に再判定（要件 D19）
        let runningIDs = Set(runningApps().map(\.bundleID))
        for item in items where item.state == .ready {
            guard !item.blockingBundleIDs.contains(where: runningIDs.contains) else {
                skipped.append(contentsOf: item.targets.map(\.url.path))
                continue
            }
            for target in item.targets {
                // 汎用 Caches の対象名は bundle id（D20）なので、実行中なら削除しない。
                // さらに許可ルート配下・スキャン時とのファイル同一性を再検証する。
                guard !runningIDs.contains(target.url.lastPathComponent),
                      CleanupTargetVerifier.isUnder(target.url, roots: item.allowedRoots),
                      CleanupTargetVerifier.isUnchanged(target, fileManager: fm) else {
                    skipped.append(target.url.path)
                    continue
                }
                let result = CleanupDeleter.deleteContents(
                    of: target.url, olderThan: item.minFileAge, now: now, fileManager: fm)
                deleted += result.deletedBytes
                skipped.append(contentsOf: result.skippedPaths)
            }
        }
        let freeAfter = storage.snapshot()?.freeBytes ?? freeBefore
        return CleanupOutcome(deletedBytes: deleted, skippedPaths: skipped,
                              freeBefore: freeBefore, freeAfter: freeAfter)
    }
}