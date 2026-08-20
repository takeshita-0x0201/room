import XCTest
@testable import Room

final class ProcessProtectionPolicyTests: XCTestCase {
    private let policy = ProcessProtectionPolicy(currentUid: 501, ownPid: 999)

    private func group(_ name: String, pid: pid_t, uid: uid_t = 501,
                       bundlePath: String? = nil, mainPath: String? = nil) -> ProcessGroup {
        ProcessGroup(id: bundlePath ?? "pid:\(pid)", displayName: name,
                     bundlePath: bundlePath, mainPath: mainPath,
                     mainPid: pid, pids: [pid], footprintBytes: 1, uid: uid)
    }

    func testAllowsRegularApp() {
        XCTAssertTrue(policy.canQuit(group("Google Chrome", pid: 100,
            bundlePath: "/Applications/Google Chrome.app",
            mainPath: "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome")))
    }

    func testDeniesSelf() {
        XCTAssertFalse(policy.canQuit(group("Room", pid: 999)))
    }

    func testDeniesPid0And1() {
        XCTAssertFalse(policy.canQuit(group("kernel_task", pid: 0, uid: 0)))
        XCTAssertFalse(policy.canQuit(group("launchd", pid: 1, uid: 0)))
    }

    func testDeniesOtherUsersProcess() {
        XCTAssertFalse(policy.canQuit(group("something", pid: 300, uid: 0)))
    }

    func testDeniesDenylistedNames() {
        for name in ["WindowServer", "Dock", "SystemUIServer", "ControlCenter",
                     "NotificationCenter", "Spotlight", "loginwindow"] {
            XCTAssertFalse(policy.canQuit(group(name, pid: 400)), name)
        }
    }

    func testDeniesCoreServicesExceptFinder() {
        XCTAssertFalse(policy.canQuit(group("Siri", pid: 500,
            bundlePath: "/System/Library/CoreServices/Siri.app",
            mainPath: "/System/Library/CoreServices/Siri.app/Contents/MacOS/Siri")))
        XCTAssertTrue(policy.canQuit(group("Finder", pid: 501,
            bundlePath: "/System/Library/CoreServices/Finder.app",
            mainPath: "/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder")))
    }
}
