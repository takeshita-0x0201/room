import XCTest
@testable import Room

final class ByteTextTests: XCTestCase {
    // Menu bar short form (requirements §9: one decimal below 100G with .0 dropped, integers at 100G+, one-letter units)
    func testShortStorage() {
        XCTAssertEqual(ByteText.short(5_600_000_000, base: .storage1000), "5.6G")
        XCTAssertEqual(ByteText.short(171_000_000_000, base: .storage1000), "171G")
        XCTAssertEqual(ByteText.short(341_000_000_000, base: .storage1000), "341G")
        XCTAssertEqual(ByteText.short(768_000_000, base: .storage1000), "768M")
    }

    func testShortMemory1024() {
        XCTAssertEqual(ByteText.short(UInt64(24) << 30, base: .memory1024), "24G")
        XCTAssertEqual(ByteText.short(19_756_849_562, base: .memory1024), "18.4G")
    }

    // Popover long form
    func testLong() {
        XCTAssertEqual(ByteText.long(19_756_849_562, base: .memory1024), "18.4 GB")
        XCTAssertEqual(ByteText.long(UInt64(24) << 30, base: .memory1024), "24 GB")
        XCTAssertEqual(ByteText.long(805_306_368, base: .memory1024), "768 MB")
        XCTAssertEqual(ByteText.long(171_000_000_000, base: .storage1000), "171 GB")
    }

    func testPair() {
        XCTAssertEqual(
            ByteText.pair(used: 19_756_849_562, total: UInt64(24) << 30, base: .memory1024),
            "18.4 / 24 GB")
        XCTAssertEqual(
            ByteText.pair(used: 341_000_000_000, total: 512_000_000_000, base: .storage1000),
            "341 / 512 GB")
    }

    func testShortTerabytes() {
        XCTAssertEqual(ByteText.short(1_200_000_000_000, base: .storage1000), "1.2T")
        XCTAssertEqual(ByteText.short(2_000_000_000_000, base: .storage1000), "2T")
    }

    func testLongTerabytes() {
        XCTAssertEqual(ByteText.long(1_200_000_000_000, base: .storage1000), "1.2 TB")
    }

    func testPairSwitchesToTerabytesForLargeVolumes() {
        XCTAssertEqual(
            ByteText.pair(used: 341_000_000_000, total: 2_000_000_000_000, base: .storage1000),
            "0.3 / 2 TB")
        // Legacy GB volumes are unchanged
        XCTAssertEqual(
            ByteText.pair(used: 341_000_000_000, total: 512_000_000_000, base: .storage1000),
            "341 / 512 GB")
    }

    func testPercent() {
        XCTAssertEqual(ByteText.percent(0.72), "72")
        XCTAssertEqual(ByteText.percent(0.666), "67")
        XCTAssertEqual(ByteText.percent(0), "0")
    }
}
