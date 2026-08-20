import XCTest
@testable import Room

final class MemoryMathTests: XCTestCase {
    func testUsedBytesFormula() {
        // Activity Monitor 準拠: (max(internal - purgeable, 0) + wired + compressor) * pageSize
        let raw = RawMemoryStats(internalPages: 1000, purgeablePages: 100,
                                 wiredPages: 300, compressorPages: 200,
                                 pageSize: 16384)
        XCTAssertEqual(MemoryMath.usedBytes(raw), (900 + 300 + 200) * 16384)
    }

    func testClampsAppMemoryBeforeAddingWiredAndCompressor() {
        // purgeable > internal でも wired / compressor は失われない（要件 D3 の式の順序）
        let raw = RawMemoryStats(internalPages: 10, purgeablePages: 100,
                                 wiredPages: 50, compressorPages: 0, pageSize: 16384)
        XCTAssertEqual(MemoryMath.usedBytes(raw), 50 * 16384)
    }

    func testPressureLevelMapping() {
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 1), .normal)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 2), .warning)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 4), .critical)
        // 未知値を Normal に倒すと誤った "No action needed" になる（要件 D21）
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 0), .unavailable)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 3), .unavailable)
    }
}
