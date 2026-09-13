import Foundation
@testable import RationsProviders
import Testing

struct TerminalScreenTests {
    @Test
    func redrawOverwritesQuotaAndIgnoresStyleAndTitle() {
        var screen = TerminalScreen()
        let stream = "\u{1B}]0;Private window title\u{7}Current session\r\n29% used"
            + "\u{1B}[2;1H\u{1B}[2K\u{1B}[32m31% used\u{1B}[0m"
        screen.consume(Data(stream.utf8))
        #expect(screen.text.contains("Current session\n31% used"))
        #expect(!screen.text.contains("29%"))
        #expect(!screen.text.contains("Private window title"))
    }

    @Test
    func eraseBelowAndSavedCursorProduceCurrentScreenOnly() {
        var screen = TerminalScreen()
        screen.consume(Data("old\r\nquota\u{1B}[1;1H\u{1B}[Jnew\u{1B}7\r\nlast\u{1B}8!".utf8))
        #expect(screen.text.hasPrefix("new!\nlast"))
        #expect(!screen.text.contains("quota"))
    }
}
