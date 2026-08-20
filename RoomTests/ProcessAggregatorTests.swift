import XCTest
@testable import Room

final class ProcessAggregatorTests: XCTestCase {
    private func raw(_ pid: pid_t, _ name: String, _ path: String?,
                     _ footprint: UInt64, uid: uid_t = 501) -> RawProcess {
        RawProcess(pid: pid, name: name, path: path, footprintBytes: footprint, uid: uid)
    }

    func testGroupsHelpersIntoOutermostAppBundle() {
        let chrome = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
        // Helper は入れ子 .app — 最初（最外）の .app で束ねる
        let helper = "/Applications/Google Chrome.app/Contents/Frameworks/F.framework/Helpers/Google Chrome Helper.app/Contents/MacOS/Google Chrome Helper"
        let groups = ProcessAggregator.aggregate([
            raw(100, "Google Chrome", chrome, 1_000_000_000),
            raw(101, "Google Chrome Helper", helper, 2_200_000_000),
        ])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].displayName, "Google Chrome")
        XCTAssertEqual(groups[0].footprintBytes, 3_200_000_000)
        XCTAssertEqual(groups[0].mainPid, 100)   // Contents/MacOS 直下が main
        XCTAssertEqual(groups[0].pids.sorted(), [100, 101])
    }

    func testStandaloneProcessIsItsOwnGroup() {
        let groups = ProcessAggregator.aggregate([
            raw(200, "node", "/usr/local/bin/node", 1_100_000_000),
        ])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].displayName, "node")
        XCTAssertNil(groups[0].bundlePath)
        XCTAssertEqual(groups[0].mainPid, 200)
    }

    func testSortedByFootprintDescending() {
        let groups = ProcessAggregator.aggregate([
            raw(1_000, "small", "/usr/bin/small", 100),
            raw(1_001, "big", "/usr/bin/big", 999),
        ])
        XCTAssertEqual(groups.map(\.displayName), ["big", "small"])
    }

    func testAppBundlePathExtraction() {
        XCTAssertEqual(
            ProcessAggregator.appBundlePath(of: "/Applications/Cursor.app/Contents/MacOS/Cursor"),
            "/Applications/Cursor.app")
        XCTAssertNil(ProcessAggregator.appBundlePath(of: "/usr/local/bin/node"))
    }
}
