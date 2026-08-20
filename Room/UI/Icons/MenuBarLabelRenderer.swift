import AppKit

/// メニューバーラベルを 1 枚のテンプレート画像に合成する（design-system §5）。
/// MenuBarExtra のラベルは複数の Image/Text を正しく描画しないため、
/// Room アイコン + Memory/Storage グリフ + 数値をここで 1 つの NSImage にまとめる。
enum MenuBarLabelRenderer {
    static func image(memory: String?, storage: String?) -> NSImage {
        let height: CGFloat = 18
        let spacing: CGFloat = 6
        let iconTextGap: CGFloat = 2
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,   // template 画像なので実際の色は OS が決める
        ]
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 11, weight: .medium)

        func symbol(_ name: String) -> NSImage? {
            NSImage(systemSymbolName: name, accessibilityDescription: nil)?
                .withSymbolConfiguration(symbolConfiguration)
        }

        var segments: [(icon: NSImage?, text: NSAttributedString?)] = []
        if let memory {
            segments.append((symbol("memorychip"),
                             NSAttributedString(string: memory, attributes: textAttributes)))
        }
        if let storage {
            segments.append((symbol("internaldrive"),
                             NSAttributedString(string: storage, attributes: textAttributes)))
        }
        // 両方 OFF のときはラベルが空になりクリック不能になるため、Room アイコンのみ表示
        if segments.isEmpty {
            segments = [(RoomIcon.menuBarImage(pointSize: 16), nil)]
        }

        var width: CGFloat = 0
        for (index, segment) in segments.enumerated() {
            if index > 0 { width += spacing }
            if let icon = segment.icon { width += icon.size.width }
            if let text = segment.text {
                if segment.icon != nil { width += iconTextGap }
                width += ceil(text.size().width)
            }
        }

        let image = NSImage(size: NSSize(width: ceil(width), height: height),
                            flipped: false) { rect in
            var x: CGFloat = 0
            for (index, segment) in segments.enumerated() {
                if index > 0 { x += spacing }
                if let icon = segment.icon {
                    let iconY = ((rect.height - icon.size.height) / 2).rounded()
                    icon.draw(in: NSRect(x: x, y: iconY,
                                         width: icon.size.width, height: icon.size.height))
                    x += icon.size.width
                }
                if let text = segment.text {
                    if segment.icon != nil { x += iconTextGap }
                    let textSize = text.size()
                    let textY = ((rect.height - textSize.height) / 2).rounded()
                    text.draw(at: NSPoint(x: x, y: textY))
                    x += ceil(textSize.width)
                }
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}