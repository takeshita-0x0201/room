import XCTest
@testable import Room

final class CleanupFileOpsTests: XCTestCase {
    private var fixture: URL!

    override func setUpWithError() throws {
        fixture = FileManager.default.temporaryDirectory
            .appendingPathComponent("RoomTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: fixture, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: fixture)
    }

    private func makeFile(_ relative: String, bytes: Int, ageDays: Double = 0) throws -> URL {
        let url = fixture.appendingPathComponent(relative)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(),
                                                withIntermediateDirectories: true)
        try Data(repeating: 0xAB, count: bytes).write(to: url)
        if ageDays > 0 {
            let old = Date().addingTimeInterval(-ageDays * 86_400)
            try FileManager.default.setAttributes([.modificationDate: old], ofItemAtPath: url.path)
        }
        return url
    }

    func testSizeCountsAllFilesRecursively() throws {
        try makeFile("a/one.bin", bytes: 1_000)
        try makeFile("a/b/two.bin", bytes: 2_000)
        let size = DirectorySizer.size(of: fixture, olderThan: nil)
        XCTAssertGreaterThanOrEqual(size, 3_000)   // allocated size はブロック単位で切り上がる
    }

    func testSizeWithAgeFilterCountsOnlyOldFiles() throws {
        try makeFile("logs/old.log", bytes: 5_000, ageDays: 10)
        try makeFile("logs/new.log", bytes: 5_000, ageDays: 0)
        let all = DirectorySizer.size(of: fixture, olderThan: nil)
        let oldOnly = DirectorySizer.size(of: fixture, olderThan: 7 * 86_400)
        XCTAssertLessThan(oldOnly, all)
        XCTAssertGreaterThanOrEqual(oldOnly, 5_000)
    }

    func testDeleteContentsKeepsRootDirectory() throws {
        try makeFile("cache/x.bin", bytes: 100)
        let root = fixture.appendingPathComponent("cache")
        let result = CleanupDeleter.deleteContents(of: root, olderThan: nil,
                                                   now: Date(), fileManager: .default)
        XCTAssertGreaterThan(result.deletedBytes, 0)
        XCTAssertTrue(FileManager.default.fileExists(atPath: root.path))       // ルートは残す
        XCTAssertEqual(try FileManager.default.contentsOfDirectory(atPath: root.path), [])
    }

    func testDeleteWithAgeFilterKeepsNewFiles() throws {
        try makeFile("logs/old.log", bytes: 100, ageDays: 10)
        let newFile = try makeFile("logs/new.log", bytes: 100, ageDays: 0)
        let root = fixture.appendingPathComponent("logs")
        _ = CleanupDeleter.deleteContents(of: root, olderThan: 7 * 86_400,
                                          now: Date(), fileManager: .default)
        XCTAssertTrue(FileManager.default.fileExists(atPath: newFile.path))
        XCTAssertFalse(FileManager.default.fileExists(
            atPath: root.appendingPathComponent("old.log").path))
    }

    // --- 削除直前の再検証（要件 D19: TOCTOU / symlink 対策） ---

    func testVerifierAcceptsUnchangedDirectory() throws {
        _ = try makeFile("cache/x.bin", bytes: 10)
        let root = fixture.appendingPathComponent("cache")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        XCTAssertTrue(CleanupTargetVerifier.isUnchanged(target, fileManager: .default))
    }

    func testVerifierRejectsReplacedDirectory() throws {
        _ = try makeFile("cache/x.bin", bytes: 10)
        let root = fixture.appendingPathComponent("cache")
        let target = try XCTUnwrap(CleanupTargetVerifier.makeTarget(root, fileManager: .default))
        // スキャン後にディレクトリが差し替えられた状況（inode が変わる）
        try FileManager.default.removeItem(at: root)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        XCTAssertFalse(CleanupTargetVerifier.isUnchanged(target, fileManager: .default))
    }

    func testVerifierRejectsSymlink() throws {
        let real = fixture.appendingPathComponent("real")
        try FileManager.default.createDirectory(at: real, withIntermediateDirectories: true)
        let link = fixture.appendingPathComponent("link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: real)
        XCTAssertNil(CleanupTargetVerifier.makeTarget(link, fileManager: .default))
    }

    func testIsUnderAllowedRoots() {
        let root = URL(fileURLWithPath: "/Users/t/Library/Caches")
        XCTAssertTrue(CleanupTargetVerifier.isUnder(
            URL(fileURLWithPath: "/Users/t/Library/Caches/com.example.tool"), roots: [root]))
        XCTAssertFalse(CleanupTargetVerifier.isUnder(
            URL(fileURLWithPath: "/Users/t/Documents"), roots: [root]))
        XCTAssertFalse(CleanupTargetVerifier.isUnder(
            URL(fileURLWithPath: "/Users/t/Library/CachesEvil"), roots: [root]))
    }
}
