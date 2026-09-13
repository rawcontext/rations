import AppKit

// Food-and-rations artwork adapted from CdnMCG (CC BY-SA 4.0).
// Attribution and modification details are bundled in IconAttribution.txt.
@MainActor
enum StatusGlyph {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in
            NSColor.black.set()
            let center = NSPoint(x: 8.9, y: 8)
            let symbol = NSBezierPath()
            symbol.move(to: center)
            symbol.appendArc(
                withCenter: center, radius: 6.4,
                startAngle: 45, endAngle: 315, clockwise: false
            )
            symbol.close()
            symbol.lineWidth = 1.2
            symbol.lineJoinStyle = .miter
            symbol.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }()
}
