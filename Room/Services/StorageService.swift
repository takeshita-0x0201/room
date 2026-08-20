import Foundation

protocol StorageStatsProviding {
    func snapshot() -> StorageSnapshot?
}

final class StorageService: StorageStatsProviding {
    private let volumeURL: URL

    init(volumeURL: URL = URL(fileURLWithPath: "/")) {
        self.volumeURL = volumeURL
    }

    func snapshot() -> StorageSnapshot? {
        guard let values = try? volumeURL.resourceValues(forKeys: [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey,   // Finder と同じ「重要用途で使える空き」(purgeable 込み)
        ]),
            let total = values.volumeTotalCapacity,
            let free = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        return StorageSnapshot(totalBytes: UInt64(total), freeBytes: UInt64(free))
    }
}
