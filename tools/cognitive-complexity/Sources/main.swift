import CognitiveLint
import Foundation
import SwiftParser

var failed = false
for path in CommandLine.arguments.dropFirst() {
    do {
        let source = try String(contentsOfFile: path, encoding: .utf8)
        let tree = Parser.parse(source: source)
        if tree.hasError {
            print("\(path):1:1: error: Swift syntax could not be parsed (cognitive_complexity)")
            failed = true
            continue
        }
        let visitor = ComplexityVisitor(file: path, tree: tree)
        visitor.walk(tree)
        visitor.violations.forEach { print($0) }
        failed = failed || !visitor.violations.isEmpty
    } catch {
        print("\(path):1:1: error: \(error)")
        failed = true
    }
}
exit(failed ? 1 : 0)
