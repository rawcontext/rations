import AppKit
import RationsCore

enum StatusGlyph {
    static func image(selection: MenuSelection?) -> NSImage {
        let remaining = selection?.window.remainingPercent ?? 0
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in
            NSColor.black.set()
            let circle = NSBezierPath(ovalIn: NSRect(x: 1.5, y: 1.5, width: 13, height: 13))
            circle.lineWidth = 1.1
            circle.stroke()
            if remaining >= 100 {
                circle.fill()
            } else if remaining > 0 {
                let slice = NSBezierPath()
                slice.move(to: NSPoint(x: 8, y: 8))
                slice.appendArc(
                    withCenter: NSPoint(x: 8, y: 8), radius: 5.3,
                    startAngle: 90, endAngle: 90 - CGFloat(remaining) * 3.6, clockwise: true
                )
                slice.close()
                slice.fill()
            }
            return true
        }
        image.isTemplate = true
        return image
    }
}
