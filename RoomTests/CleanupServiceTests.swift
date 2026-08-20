import XCTest
@testable import Room

/// CleanupService の scan/delete をフィクスチャ限定で検証する（実ユーザーデータ禁止）。
final class CleanupServiceTests: XCTestCase {
    private var fixture: URL!

    private struct StorageStub: StorageStatsProviding {
        func snapshot() -> StorageSnapshot? {
            StorageSnapshot(totalBytes: 1_000, freeBytes: 500)
        }
    }

    override func setUpWithError() throws {
        fixture = FileManager.default.temporaryDirectory
            .appendingPathComponent("RoomServiceTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fixture)
    }

    private func makeFile(_ relative: String, bytes: Int = 100) throws -> URL {
        let url = fixture.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data(repeating: 0xCD, count: bytes).write(to: url)
        return url
    }

    private func rule(_ id: String, roots: [URL], blocking: [String] = []) -> CleanupRule {
        CleanupRule(id: id, title: id, summaryGroup: .caches, roots: roots,
                    minFileAge: nil, blockingBundleIDs: blocking,
                    requiresFullDiskAccess: false, isGenericCachesScan: false)
    }

    private func service(rules: [CleanupRule],
                         running: [RunningApp] = []) -> CleanupService {
        CleanupService(rules: rules, storage: StorageStub(), runningApps: { running })
    }

    private func item(_ id: String, target: CleanupTarget, allowedRoots: [URL]) -> CleanupItem {
        CleanupItem(id: id, title: id, summaryGroup: .caches,
                    targets: [target], allowedRoots: allowedRoots,
                    blockingBundleIDs: [], minFileAge: nil,
                    sizeBytes: 1, state: .ready)
    }

    func testDeleteRemovesContentsOfVerifiedTarget() async throws {
        let root = fixture.appendingPathComponent("cache")
        let file = try makeFile("cache/x.bin")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        let sut = service(rules: [rule("r", roots: [root])])

        let outcome = await sut.delete([item("r", target: target, allowedRoots: [root])])

        XCTAssertGreaterThan(outcome.deletedBytes, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.path))   // ルートは残す
    }

    func testDeleteSkipsWhenBlockingAppIsRunningAtDeleteTime() async throws {
        let root = fixture.appendingPathComponent("cache")
        let file = try makeFile("cache/x.bin")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        let sut = service(rules: [rule("r", roots: [root], blocking: ["com.blocker.app"])],
                          running: [RunningApp(bundleID: "com.blocker.app", name: "Blocker")])

        let outcome = await sut.delete([item("r", target: target, allowedRoots: [root])])

        XCTAssertEqual(outcome.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))   // 何も消えていない
        XCTAssertFalse(outcome.skippedPaths.isEmpty)
    }

    func testDeleteRejectsSymlinkEscapedTarget() async throws {
        // allowed/link → outside への中間 symlink。leaf 自体は通常ディレクトリなので
        // makeTarget は通るが、解決後パスの包含検証で拒否されなければならない
        let allowed = fixture.appendingPathComponent("allowed")
        try FileManager.default.createDirectory(at: allowed, withIntermediateDirectories: true)
        let outside = fixture.appendingPathComponent("outside")
        let victim = try makeFile("outside/leaf/secret.bin")
        let link = allowed.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)

        let escaped = allowed.appendingPathComponent("link/leaf")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(escaped, fileManager: .default))
        let sut = service(rules: [rule("r", roots: [allowed])])

        let outcome = await sut.delete([item("r", target: target, allowedRoots: [allowed])])

        XCTAssertEqual(outcome.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: victim.path))   // 領域外は無傷
        XCTAssertTrue(outcome.skippedPaths.contains(escaped.path))
    }

    func testDeleteIgnoresForgedItemsWithUnknownRuleID() async throws {
        // 呼び出し側が偽の allowedRoots を持つ item を渡しても、
        // サービスの rules に無い ID は削除されない（多層防御）
        let root = fixture.appendingPathComponent("cache")
        let file = try makeFile("cache/x.bin")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        let sut = service(rules: [])   // ルール無し

        let outcome = await sut.delete([item("forged", target: target, allowedRoots: [root])])

        XCTAssertEqual(outcome.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertEqual(outcome.skippedPaths, [root.path])
    }
}