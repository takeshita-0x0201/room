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
            .volumeAvailableCapacityForImportantUsageKey,   // same "available for important usage" free space as Finder (incl. purgeable)
        ]),
            let total = values.volumeTotalCapacity,
            let free = values.volumeAvailableCapacityForImportantUsage
        else { return nil }
        return StorageSnapshot(totalBytes: UInt64(total), freeBytes: UInt64(free))
    }
}
