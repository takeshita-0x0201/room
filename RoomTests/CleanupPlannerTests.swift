import XCTest
@testable import Room

final class CleanupPlannerTests: XCTestCase {
    private let caches = URL(fileURLWithPath: "/Users/t/Library/Caches")
    private func child(_ name: String) -> URL { caches.appendingPathComponent(name) }

    func testExcludesAppleCaches() {
        let result = CleanupPlanner.genericCacheChildren(
            allChildren: [child("com.apple.dt.Xcode"), child("com.jetbrains.intellij")],
            claimedRoots: [], runningBundleIDs: [])
        XCTAssertEqual(result, [child("com.jetbrains.intellij")])
    }

    func testExcludesNonReverseDNSNames() {
        // "Google" "JetBrains" etc. are not bundle IDs and can't be resolved as running → excluded (requirements D20)
        let result = CleanupPlanner.genericCacheChildren(
            allChildren: [child("Google"), child("JetBrains"), child("Yarn"),
                          child("com.example.tool")],
            claimedRoots: [], runningBundleIDs: [])
        XCTAssertEqual(result, [child("com.example.tool")])
    }

    func testExcludesClaimedRoots() {
        let result = CleanupPlanner.genericCacheChildren(
            allChildren: [child("com.example.claimed"), child("com.example.free")],
            claimedRoots: [child("com.example.claimed")], runningBundleIDs: [])
        XCTAssertEqual(result, [child("com.example.free")])
    }

    func testExcludesAncestorOfClaimedRoot() {
        // Must not delete a parent directory whose descendant is claimed
        let result = CleanupPlanner.genericCacheChildren(
            allChildren: [child("com.example.vendor")],
            claimedRoots: [child("com.example.vendor").appendingPathComponent("Sub")],
            runningBundleIDs: [])
        XCTAssertTrue(result.isEmpty)
    }

    func testExcludesRunningAppsCacheDir() {
        let result = CleanupPlanner.genericCacheChildren(
            allChildren: [child("com.google.Chrome"), child("com.example.tool")],
            claimedRoots: [], runningBundleIDs: ["com.google.Chrome"])
        XCTAssertEqual(result, [child("com.example.tool")])
    }
}