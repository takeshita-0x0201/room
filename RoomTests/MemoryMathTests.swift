import XCTest
@testable import Room

final class MemoryMathTests: XCTestCase {
    func testUsedBytesFormula() {
        // Activity Monitor compliant: (max(internal - purgeable, 0) + wired + compressor) * pageSize
        let raw = RawMemoryStats(internalPages: 1000, purgeablePages: 100,
                                 wiredPages: 300, compressorPages: 200,
                                 pageSize: 16384)
        XCTAssertEqual(MemoryMath.usedBytes(raw), (900 + 300 + 200) * 16384)
    }

    func testClampsAppMemoryBeforeAddingWiredAndCompressor() {
        // wired / compressor aren't lost even when purgeable > internal (order of the requirements D3 formula)
        let raw = RawMemoryStats(internalPages: 10, purgeablePages: 100,
                                 wiredPages: 50, compressorPages: 0, pageSize: 16384)
        XCTAssertEqual(MemoryMath.usedBytes(raw), 50 * 16384)
    }

    func testPressureLevelMapping() {
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 1), .normal)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 2), .warning)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 4), .critical)
        // Falling back to Normal on unknown values would show an incorrect "No action needed" (requirements D21)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 0), .unavailable)
        XCTAssertEqual(MemoryMath.pressureLevel(fromSysctl: 3), .unavailable)
    }
}
