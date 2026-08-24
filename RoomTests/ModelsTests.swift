import XCTest
@testable import Room

final class ModelsTests: XCTestCase {
    func testMemorySnapshotComputed() {
        let s = MemorySnapshot(totalBytes: 100, usedBytes: 72,
                               swapUsedBytes: 0, pressure: .normal)
        XCTAssertEqual(s.freeBytes, 28)
        XCTAssertEqual(s.usedFraction, 0.72, accuracy: 0.0001)
    }

    func testMemorySnapshotNeverUnderflows() {
        let s = MemorySnapshot(totalBytes: 100, usedBytes: 120,
                               swapUsedBytes: 0, pressure: .critical)
        XCTAssertEqual(s.freeBytes, 0)
    }

    func testStorageSnapshotComputed() {
        let s = StorageSnapshot(totalBytes: 512, freeBytes: 171)
        XCTAssertEqual(s.usedBytes, 341)
        XCTAssertEqual(s.usedFraction, 341.0 / 512.0, accuracy: 0.0001)
    }

    func testPressureLabels() {
        XCTAssertEqual(MemoryPressureLevel.normal.rawValue, "Normal")
        XCTAssertEqual(MemoryPressureLevel.warning.rawValue, "Warning")
        XCTAssertEqual(MemoryPressureLevel.critical.rawValue, "Critical")
        XCTAssertEqual(MemoryPressureLevel.unavailable.rawValue, "Unavailable")
    }

    func testAppearanceModeTitles() {
        XCTAssertEqual(AppearanceMode.allCases.map(\.title), ["System", "Light", "Dark"])
    }
}
