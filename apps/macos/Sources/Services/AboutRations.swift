import AppKit

@MainActor
enum AboutRations {
    static func show() {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.paragraphSpacing = 8
        let tagline = "If you have to ask when it resets, you’re already in line."
        let links = [("GitHub", "https://github.com/rawcontext/rations"),
                     ("© Context", "https://rawcontext.com")]
        let credits = NSMutableAttributedString(string: tagline + "\n\n", attributes: [
            .font: NSFont.systemFont(ofSize: 13), .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph
        ])
        for (title, address) in links {
            credits.append(NSAttributedString(string: title + "\n", attributes: [
                .link: address, .font: NSFont.systemFont(ofSize: 12), .paragraphStyle: paragraph
            ]))
        }
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Rations", .applicationIcon: StatusGlyph.image,
            .credits: credits
        ])
        NSApp.activate(ignoringOtherApps: true)
    }
}
