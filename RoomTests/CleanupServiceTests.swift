import XCTest
@testable import Room

/// Verifies CleanupService scan/delete strictly against fixtures (real user data is forbidden).
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

    private func item(_ id: String, target: CleanupTarget) -> CleanupItem {
        CleanupItem(id: id, title: id, summaryGroup: .caches,
                    targets: [target], sizeBytes: 1, state: .ready)
    }

    func testDeleteRemovesContentsOfVerifiedTarget() async throws {
        let root = fixture.appendingPathComponent("cache")
        let file = try makeFile("cache/x.bin")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        let sut = service(rules: [rule("r", roots: [root])])

        let outcome = await sut.delete([item("r", target: target)])

        XCTAssertGreaterThan(outcome.deletedBytes, 0)
        XCTAssertFalse(FileManager.default.fileExists(atPath: file.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.path))   // root is kept
    }

    func testDeleteSkipsWhenBlockingAppIsRunningAtDeleteTime() async throws {
        let root = fixture.appendingPathComponent("cache")
        let file = try makeFile("cache/x.bin")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        let sut = service(rules: [rule("r", roots: [root], blocking: ["com.blocker.app"])],
                          running: [RunningApp(bundleID: "com.blocker.app", name: "Blocker")])

        let outcome = await sut.delete([item("r", target: target)])

        XCTAssertEqual(outcome.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))   // nothing was deleted
        XCTAssertFalse(outcome.skippedPaths.isEmpty)
    }

    func testDeleteRejectsSymlinkEscapedTarget() async throws {
        // allowed/link → intermediate symlink to outside. The leaf itself is a normal directory, so
        // makeTarget passes, but the resolved-path containment check must reject it
        let allowed = fixture.appendingPathComponent("allowed")
        try FileManager.default.createDirectory(at: allowed, withIntermediateDirectories: true)
        let outside = fixture.appendingPathComponent("outside")
        let victim = try makeFile("outside/leaf/secret.bin")
        let link = allowed.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: outside)

        let escaped = allowed.appendingPathComponent("link/leaf")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(escaped, fileManager: .default))
        let sut = service(rules: [rule("r", roots: [allowed])])

        let outcome = await sut.delete([item("r", target: target)])

        XCTAssertEqual(outcome.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: victim.path))   // the area outside is untouched
        XCTAssertTrue(outcome.skippedPaths.contains(escaped.path))
    }

    func testDeleteIgnoresForgedItemsWithUnknownRuleID() async throws {
        // Even if the caller passes a forged item with an ID absent from the rules,
        // IDs unknown to the service's rules are never deleted (defense in depth — nothing but the ID is trusted)
        let root = fixture.appendingPathComponent("cache")
        let file = try makeFile("cache/x.bin")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        let sut = service(rules: [])   // no rules

        let outcome = await sut.delete([item("forged", target: target)])

        XCTAssertEqual(outcome.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: file.path))
        XCTAssertEqual(outcome.skippedPaths, [root.path])
    }
}