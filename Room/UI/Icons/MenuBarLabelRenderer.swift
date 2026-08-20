import AppKit

/// Composes the menu bar label into a single template image (design-system §5).
/// MenuBarExtra's label does not render multiple Image/Text correctly, so the
/// Room icon + Memory/Storage glyphs + values are combined into one NSImage here.
enum MenuBarLabelRenderer {
    static func image(memory: String?, storage: String?) -> NSImage {
        let height: CGFloat = 20
        let spacing: CGFloat = 6
        let iconTextGap: CGFloat = 2
        let font = NSFont.monospacedDigitSystemFont(ofSize: 14, weight: .medium)
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.black,   // a template image, so the actual color is decided by the OS
        ]
        let symbolConfiguration = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)

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
        // With both OFF the label would be empty and unclickable, so show only the Room icon
        if segments.isEmpty {
            segments = [(RoomIcon.menuBarImage(pointSize: 18), nil)]
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