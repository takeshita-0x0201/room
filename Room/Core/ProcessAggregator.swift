import Foundation

/// 生プロセス一覧を「アプリ単位」に集約する（要件 §6.3）。純粋関数。
enum ProcessAggregator {
    static func aggregate(_ raw: [RawProcess]) -> [ProcessGroup] {
        var appBuckets: [String: [RawProcess]] = [:]
        var standalone: [RawProcess] = []
        for process in raw {
            if let path = process.path, let bundle = appBundlePath(of: path) {
                appBuckets[bundle, default: []].append(process)
            } else {
                standalone.append(process)
            }
        }

        var groups: [ProcessGroup] = []
        for (bundle, members) in appBuckets {
            let main = mainProcess(in: members, bundlePath: bundle)
            let name = ((bundle as NSString).lastPathComponent as NSString).deletingPathExtension
            groups.append(ProcessGroup(
                id: bundle,
                displayName: name,
                bundlePath: bundle,
                mainPath: main.path,
                mainPid: main.pid,
                pids: members.map(\.pid),
                footprintBytes: members.reduce(0) { $0 + $1.footprintBytes },
                uid: main.uid
            ))
        }
        for process in standalone {
            groups.append(ProcessGroup(
                id: "pid:\(process.pid)",
                displayName: process.name,
                bundlePath: nil,
                mainPath: process.path,
                mainPid: process.pid,
                pids: [process.pid],
                footprintBytes: process.footprintBytes,
                uid: process.uid
            ))
        }
        return groups.sorted { $0.footprintBytes > $1.footprintBytes }
    }

    /// 最初（最外）の ".app" までのパス。Chrome Helper のような入れ子 .app を親アプリへ束ねる。
    static func appBundlePath(of path: String) -> String? {
        let components = path.split(separator: "/")
        guard let index = components.firstIndex(where: { $0.hasSuffix(".app") }) else { return nil }
        return "/" + components[...index].joined(separator: "/")
    }

    private static func mainProcess(in members: [RawProcess], bundlePath: String) -> RawProcess {
        let mainPrefix = bundlePath + "/Contents/MacOS/"
        let mains = members.filter { process in
            guard let path = process.path, path.hasPrefix(mainPrefix) else { return false }
            return !path.dropFirst(mainPrefix.count).contains("/")
        }
        return mains.min { $0.pid < $1.pid } ?? members.min { $0.pid < $1.pid }!
    }
}
