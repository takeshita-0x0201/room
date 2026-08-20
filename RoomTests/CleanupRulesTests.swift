import XCTest
@testable import Room

final class CleanupRulesTests: XCTestCase {
    private let rules = CleanupRules.standard(
        home: URL(fileURLWithPath: "/Users/t"),
        tmpDir: URL(fileURLWithPath: "/tmp/user"))

    func testExactlyOneGenericCachesRule() {
        XCTAssertEqual(rules.filter(\.isGenericCachesScan).count, 1)
    }

    func testTrashRequiresFullDiskAccess() {
        let trash = rules.first { $0.id == "trash" }!
        XCTAssertTrue(trash.requiresFullDiskAccess)
        XCTAssertEqual(trash.roots, [URL(fileURLWithPath: "/Users/t/.Trash")])
    }

    func testBrowserRulesBlockOnRunningBrowser() {
        XCTAssertEqual(rules.first { $0.id == "chrome-cache" }!.blockingBundleIDs, ["com.google.Chrome"])
        XCTAssertEqual(rules.first { $0.id == "firefox-cache" }!.blockingBundleIDs, ["org.mozilla.firefox"])
    }

    func testAgeThresholds() {
        XCTAssertEqual(rules.first { $0.id == "logs" }!.minFileAge, 7 * 86_400)      // 要件 D14
        XCTAssertEqual(rules.first { $0.id == "temp-files" }!.minFileAge, 3 * 86_400)
    }

    func testSummaryTotals() {
        func item(_ id: String, _ group: CleanupSummaryGroup, _ bytes: UInt64) -> CleanupItem {
            CleanupItem(id: id, title: id, summaryGroup: group, targets: [],
                        sizeBytes: bytes, state: .ready)
        }
        let items = [item("a", .caches, 100), item("b", .caches, 50), item("c", .developer, 70)]
        let totals = CleanupSummary.totals(items)
        XCTAssertEqual(totals[.caches], 150)
        XCTAssertEqual(totals[.developer], 70)
        XCTAssertEqual(CleanupSummary.grandTotal(items), 220)
    }
}