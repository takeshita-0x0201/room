import AppKit
import UniformTypeIdentifiers

/// プロセス行に表示するアプリアイコン（design-system §6/§7）。
/// .app グループは実アイコン、非アプリプロセスは汎用実行ファイルアイコン。
enum AppIconProvider {
    static func icon(for group: ProcessGroup, size: CGFloat = 16) -> NSImage {
        let base: NSImage
        if let bundlePath = group.bundlePath {
            base = NSWorkspace.shared.icon(forFile: bundlePath)
        } else {
            base = NSWorkspace.shared.icon(for: .unixExecutable)
        }
        let copy = base.copy() as! NSImage
        copy.size = NSSize(width: size, height: size)
        return copy
    }
}
