import SwiftSyntax

public final class ComplexityVisitor: SyntaxAnyVisitor {
    public static let limit = 15

    private let locationConverter: SourceLocationConverter
    public private(set) var violations: [String] = []

    public init(file: String, tree: SourceFileSyntax) {
        locationConverter = SourceLocationConverter(fileName: file, tree: tree)
        super.init(viewMode: .sourceAccurate)
    }

    override public func visitAny(_ node: Syntax) -> SyntaxVisitorContinueKind {
        if let function = node.as(FunctionDeclSyntax.self), let body = function.body {
            check(Syntax(body), at: node, name: function.name.text)
        } else if let initializer = node.as(InitializerDeclSyntax.self), let body = initializer.body {
            check(Syntax(body), at: node)
        } else if let accessor = node.as(AccessorDeclSyntax.self), let body = accessor.body {
            check(Syntax(body), at: node)
        } else if let block = node.as(AccessorBlockSyntax.self), case .getter(let body) = block.accessors {
            check(Syntax(body), at: node)
        } else if let closure = node.as(ClosureExprSyntax.self) {
            check(Syntax(closure.statements), at: node)
        } else if let deinitializer = node.as(DeinitializerDeclSyntax.self), let body = deinitializer.body {
            check(Syntax(body), at: node)
        }
        return .visitChildren
    }

    private func check(_ body: Syntax, at node: Syntax, name: String = "") {
        let complexity = CognitiveComplexity.score(body, functionName: name)
        guard complexity > Self.limit else { return }
        let location = locationConverter.location(for: node.positionAfterSkippingLeadingTrivia)
        violations.append(
            "\(location.file):\(location.line):\(location.column): error: "
                + "Cognitive complexity \(complexity) exceeds \(Self.limit) (cognitive_complexity)"
        )
    }
}
