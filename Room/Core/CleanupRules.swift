import Foundation

/// Definitions of cleanup targets (requirements §18.2). This file is the single source of truth for paths.
enum CleanupRules {
    static let day: TimeInterval = 86_400

    static func standard(home: URL, tmpDir: URL) -> [CleanupRule] {
        let library = home.appendingPathComponent("Library")
        let caches = library.appendingPathComponent("Caches")

        func rule(_ id: String, _ title: String, _ group: CleanupSummaryGroup,
                  roots: [URL], age: TimeInterval? = nil,
                  blocking: [String] = [], fda: Bool = false,
                  generic: Bool = false) -> CleanupRule {
            CleanupRule(id: id, title: title, summaryGroup: group, roots: roots,
                        minFileAge: age, blockingBundleIDs: blocking,
                        requiresFullDiskAccess: fda, isGenericCachesScan: generic)
        }

        return [
            rule("app-caches", "Application Cache", .caches, roots: [caches], generic: true),
            rule("chrome-cache", "Chrome Cache", .caches,
                 roots: [caches.appendingPathComponent("Google/Chrome")],
                 blocking: ["com.google.Chrome"]),
            rule("firefox-cache", "Firefox Cache", .caches,
                 roots: [caches.appendingPathComponent("Firefox")],
                 blocking: ["org.mozilla.firefox"]),
            rule("temp-files", "Temporary Files", .caches,
                 roots: [tmpDir], age: 3 * day),
            rule("logs", "Logs", .logs,
                 roots: [library.appendingPathComponent("Logs")], age: 7 * day),
            rule("xcode-derived-data", "Xcode DerivedData", .developer,
                 roots: [library.appendingPathComponent("Developer/Xcode/DerivedData")],
                 blocking: ["com.apple.dt.Xcode"]),
            rule("simulator-caches", "Simulator Cache", .developer,
                 roots: [library.appendingPathComponent("Developer/CoreSimulator/Caches")],
                 blocking: ["com.apple.dt.Xcode"]),
            rule("xcode-caches", "Xcode Cache", .developer,
                 roots: [caches.appendingPathComponent("com.apple.dt.Xcode")],
                 blocking: ["com.apple.dt.Xcode"]),
            rule("npm-cache", "npm Cache", .developer,
                 roots: [home.appendingPathComponent(".npm/_cacache")]),
            rule("pnpm-store", "pnpm Store", .developer,
                 roots: [library.appendingPathComponent("pnpm/store"),
                         home.appendingPathComponent(".local/share/pnpm/store"),
                         home.appendingPathComponent(".pnpm-store")]),
            rule("yarn-cache", "Yarn Cache", .developer,
                 roots: [caches.appendingPathComponent("Yarn")]),
            rule("homebrew-cache", "Homebrew Cache", .developer,
                 roots: [caches.appendingPathComponent("Homebrew")]),
            rule("cocoapods-cache", "CocoaPods Cache", .developer,
                 roots: [caches.appendingPathComponent("CocoaPods")]),
            rule("gradle-cache", "Gradle Cache", .developer,
                 roots: [home.appendingPathComponent(".gradle/caches")]),
            rule("trash", "Trash", .trash,
                 roots: [home.appendingPathComponent(".Trash")], fda: true),
        ]
    }
}