import AppKit
import SwiftUI

enum RoomIcon {
    /// An open room with only 3 faces (requirements §8: a faceless 3D space). Coordinate system is 100x100 (flipped: y points down).
    /// - Rear rim: D(16,30) — A(50,12) — B(84,30)
    /// - Vertical edges: D→D'(16,66), A→A'(50,48), B→B'(84,66)
    /// - Floor diamond: D'(16,66) — A'(50,48) — B'(84,66) — C'(50,84) — close
    /// Front and top edges are not drawn.
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
        image.isTemplate = true   // the OS flips it automatically for Light / Dark
        return image
    }
}
