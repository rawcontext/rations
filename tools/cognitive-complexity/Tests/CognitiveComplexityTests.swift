import CognitiveLint
import SwiftParser
import SwiftSyntax
import Testing

struct CognitiveComplexityTests {
    @Test(arguments: [
        ("return 1", 0),
        ("if a { if b { work() } }", 3),
        ("if a { work() } else if b { work() } else { work() }", 3),
        ("for item in items { if item { work() } }", 3),
        ("guard a else { return }; if b { work() }", 2),
        ("switch value { case 1: work(); case 2: work(); default: break }", 1),
        ("do { try work() } catch { if a { work() } }", 3),
        ("if a && b && c || d { work() }", 3),
        ("items.map { item in if item { work() } }", 2),
        ("outer: while a { if b { break outer } }", 4),
        ("recurse()", 1),
        ("return a ? b : c", 1),
        ("return a ? b : c ? d : e", 3),
        ("return a ? (b ? c : d) : e", 3),
        (#"let text = "if for while" // if if if"#, 0)
    ])
    func scoresControlFlow(body: String, expected: Int) throws {
        let tree = Parser.parse(source: "func recurse() {\n\(body)\n}")
        let function = try #require(tree.statements.first?.item.as(FunctionDeclSyntax.self))
        let functionBody = try #require(function.body)
        #expect(CognitiveComplexity.score(Syntax(functionBody), functionName: "recurse") == expected)
    }

    @Test
    func reportsSourceLocationAndLimit() {
        let branches = String(repeating: "if ready { print(ready) }\n", count: 16)
        let tree = Parser.parse(source: "func work() {\n\(branches)}")
        let visitor = ComplexityVisitor(file: "Example.swift", tree: tree)
        visitor.walk(tree)
        #expect(visitor.violations.count == 1)
        #expect(visitor.violations.first?.contains("Example.swift:1:1: error:") == true)
        #expect(visitor.violations.first?.contains("Cognitive complexity 16 exceeds 15") == true)
    }

    @Test
    func checksInitializersAndComputedProperties() {
        let branches = String(repeating: "if ready { print(ready) }; ", count: 16)
        let source = "struct Sample { init() { \(branches) } var value: Int { \(branches) return 1 } }"
        let tree = Parser.parse(source: source)
        let visitor = ComplexityVisitor(file: "Sample.swift", tree: tree)
        visitor.walk(tree)
        #expect(visitor.violations.count == 2)
    }
}
