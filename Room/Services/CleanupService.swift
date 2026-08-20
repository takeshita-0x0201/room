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
        for item in items where item.state == .ready {
            // 呼び出し側の allowedRoots / 条件は信用しない。
            // ルート・age・ブロッカーはサービス自身の rules から ID で再導出する（多層防御）
            guard let rule = rules.first(where: { $0.id == item.id }) else {
                skipped.append(contentsOf: item.targets.map(\.url.path))
                continue
            }
            // 実行中アプリの再判定は「項目ごと」に行う — 前の項目を削除している間に
            // 対象アプリが起動され得るため、開始時スナップショットを使い回さない
            let runningIDs = Set(runningApps().map(\.bundleID))
            guard !rule.blockingBundleIDs.contains(where: runningIDs.contains) else {
                skipped.append(contentsOf: item.targets.map(\.url.path))
                continue
            }
            let resolvedRoots = rule.roots.map { $0.resolvingSymlinksInPath() }
            for target in item.targets {
                // 中間 symlink による許可領域外への脱出を防ぐ:
                // 字句パスの包含に加え、symlink 解決後の実体パスでも包含を要求する
                let resolvedTarget = target.url.resolvingSymlinksInPath()
                guard !runningIDs.contains(target.url.lastPathComponent),
                      CleanupTargetVerifier.isUnder(target.url, roots: rule.roots),
                      CleanupTargetVerifier.isUnder(resolvedTarget, roots: resolvedRoots),
                      CleanupTargetVerifier.isUnchanged(target, fileManager: fm) else {
                    skipped.append(target.url.path)
                    continue
                }
                let result = CleanupDeleter.deleteContents(
                    of: target.url, olderThan: rule.minFileAge, now: now, fileManager: fm)
                deleted += result.deletedBytes
                skipped.append(contentsOf: result.skippedPaths)
            }
        }
        let freeAfter = storage.snapshot()?.freeBytes ?? freeBefore
        return CleanupOutcome(deletedBytes: deleted, skippedPaths: skipped,
                              freeBefore: freeBefore, freeAfter: freeAfter)
    }
}