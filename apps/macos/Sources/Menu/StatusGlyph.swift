import AppKit

@MainActor
enum StatusGlyph {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { _ in
            NSColor.black.set()
            let circle = NSBezierPath(ovalIn: NSRect(x: 1.5, y: 1.5, width: 13, height: 13))
            circle.lineWidth = 1.1
            circle.stroke()
            let slice = NSBezierPath()
            slice.move(to: NSPoint(x: 8, y: 8))
            slice.appendArc(
                withCenter: NSPoint(x: 8, y: 8), radius: 5.3,
                startAngle: 90, endAngle: -60, clockwise: true
            )
            slice.close()
            slice.fill()
            if let context = NSGraphicsContext.current?.cgContext {
                context.saveGState()
                context.setBlendMode(.clear)
                context.setLineWidth(0.8)
                context.move(to: CGPoint(x: 8, y: 8))
                let angle = CGFloat.pi / 12
                context.addLine(to: CGPoint(x: 8 + 5.5 * cos(angle), y: 8 + 5.5 * sin(angle)))
                context.strokePath()
                context.restoreGState()
            }
            return true
        }
        image.isTemplate = true
        return image
    }()
}
