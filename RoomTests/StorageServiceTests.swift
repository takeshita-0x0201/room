import XCTest
@testable import Room

final class StorageServiceTests: XCTestCase {
    func testRootVolumeSnapshot() throws {
        let snapshot = StorageService().snapshot()
        let s = try XCTUnwrap(snapshot)
        XCTAssertGreaterThan(s.totalBytes, 0)
        XCTAssertGreaterThan(s.freeBytes, 0)
        XCTAssertLessThanOrEqual(s.freeBytes, s.totalBytes)
    }
}
