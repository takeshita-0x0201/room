import XCTest
@testable import Room

final class MenuBarTextTests: XCTestCase {
    private let memory = MemorySnapshot(totalBytes: UInt64(24) << 30,
                                        usedBytes: 19_756_849_562,
                                        swapUsedBytes: 0, pressure: .normal)
    private let storage = StorageSnapshot(totalBytes: 512_000_000_000,
                                          freeBytes: 171_000_000_000)

    func testPercentageMode() {
        XCTAssertEqual(MenuBarText.memoryValue(memory, mode: .percentage), "77")
        XCTAssertEqual(MenuBarText.storageValue(storage, mode: .percentage), "67")
    }

    func testFreeMode() {
        XCTAssertEqual(MenuBarText.memoryValue(memory, mode: .free), "5.6G")
        XCTAssertEqual(MenuBarText.storageValue(storage, mode: .free), "171G")
    }

    func testUsedMode() {
        XCTAssertEqual(MenuBarText.memoryValue(memory, mode: .used), "18.4G")
        XCTAssertEqual(MenuBarText.storageValue(storage, mode: .used), "341G")
    }

    func testNilSnapshotShowsDash() {
        XCTAssertEqual(MenuBarText.memoryValue(nil, mode: .percentage), "–")
        XCTAssertEqual(MenuBarText.storageValue(nil, mode: .free), "–")
    }
}
