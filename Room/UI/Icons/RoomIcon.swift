import AppKit
import SwiftUI

enum RoomIcon {
    /// 3 面だけのオープンな部屋（要件 §8: 面のない立体空間）。座標系は 100x100（flipped: y 下向き）。
    /// - 奥のリム: D(16,30) — A(50,12) — B(84,30)
    /// - 縦エッジ: D→D'(16,66), A→A'(50,48), B→B'(84,66)
    /// - 床のダイヤ: D'(16,66) — A'(50,48) — B'(84,66) — C'(50,84) — 閉じる
    /// 前面・上面のエッジは描かない。
    static func menuBarImage(pointSize: CGFloat = 18) -> NSImage {
        let image = NSImage(size: NSSize(width: pointSize, height: pointSize),
                            flipped: true) { rect in
            let s = rect.width / 100.0
            func p(_ x: CGFloat, _ y: CGFloat) -> NSPoint { NSPoint(x: x * s, y: y * s) }

            let path = NSBezierPath()
            path.lineWidth = max(1.2, 8 * s)
            path.lineCapStyle = .round
            path.lineJoinStyle = .round

            path.move(to: p(16, 30)); path.line(to: p(50, 12)); path.line(to: p(84, 30))
            path.move(to: p(16, 30)); path.line(to: p(16, 66))
            path.move(to: p(50, 12)); path.line(to: p(50, 48))
            path.move(to: p(84, 30)); path.line(to: p(84, 66))
            path.move(to: p(16, 66)); path.line(to: p(50, 48))
            path.line(to: p(84, 66)); path.line(to: p(50, 84)); path.close()

            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true   // Light / Dark を OS が自動反転
        return image
    }
}
