import AppKit
import SwiftUI

enum RoomIcon {
    /// 3 面だけのオープンな部屋（要件 §8: 面のない立体空間）。座標系は 100x100（flipped: y 下向き）。
    /// - 奥のリム: D(10,38) — A(50,18) — B(90,38)
    /// - 縦エッジ: D→D'(10,66), A→A'(50,46), B→B'(90,66)
    /// - 床のダイヤ: D'(10,66) — A'(50,46) — B'(90,66) — C'(50,86) — 閉じる
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

            path.move(to: p(10, 38)); path.line(to: p(50, 18)); path.line(to: p(90, 38))
            path.move(to: p(10, 38)); path.line(to: p(10, 66))
            path.move(to: p(50, 18)); path.line(to: p(50, 46))
            path.move(to: p(90, 38)); path.line(to: p(90, 66))
            path.move(to: p(10, 66)); path.line(to: p(50, 46))
            path.line(to: p(90, 66)); path.line(to: p(50, 86)); path.close()

            NSColor.black.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true   // Light / Dark を OS が自動反転
        return image
    }
}
