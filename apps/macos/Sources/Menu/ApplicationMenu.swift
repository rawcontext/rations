import AppKit

@MainActor
enum ApplicationMenu {
    static func make() -> NSMenu {
        let main = NSMenu()
        let app = NSMenuItem()
        app.submenu = NSMenu(title: "Rations")
        app.submenu?.addItem(MenuCommand("Quit Rations", key: "q") { NSApp.terminate(nil) })
        main.addItem(app)
        let edit = NSMenuItem()
        edit.submenu = NSMenu(title: "Edit")
        let commands = [("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"),
                        ("Select All", "selectAll:", "a")]
        for command in commands {
            edit.submenu?.addItem(NSMenuItem(
                title: command.0, action: Selector(command.1), keyEquivalent: command.2
            ))
        }
        main.addItem(edit)
        return main
    }
}
