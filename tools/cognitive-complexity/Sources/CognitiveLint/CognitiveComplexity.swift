import SwiftSyntax

public struct CognitiveComplexity {
    private static let nestedKinds: Set<SyntaxKind> = [
        .forStmt, .whileStmt, .repeatStmt, .guardStmt, .switchExpr, .catchClause
    ]

    public static func score(_ node: Syntax, nesting: Int = 0, functionName: String = "") -> Int {
        if let branch = node.as(IfExprSyntax.self) {
            return scoreBranch(branch, nesting: nesting, functionName: functionName)
        }
        if let sequence = node.as(SequenceExprSyntax.self) {
            return scoreSequence(sequence, nesting: nesting, functionName: functionName)
        }
        let isStructural = nestedKinds.contains(node.kind)
        let nestedScope = node.is(ClosureExprSyntax.self) || node.is(FunctionDeclSyntax.self)
        let depth = nesting + (isStructural || nestedScope ? 1 : 0)
        let children = node.children(viewMode: .sourceAccurate).reduce(0) {
            $0 + score($1, nesting: depth, functionName: functionName)
        }
        return children + (isStructural ? 1 + nesting : 0) + flatIncrement(node, functionName: functionName)
    }

    private static func scoreBranch(_ branch: IfExprSyntax, nesting: Int, functionName: String) -> Int {
        let condition = score(Syntax(branch.conditions), nesting: nesting, functionName: functionName)
        let body = score(Syntax(branch.body), nesting: nesting + 1, functionName: functionName)
        guard let alternative = branch.elseBody else {
            return 1 + nesting + condition + body
        }
        let alternativeScore: Int
        if let nextBranch = alternative.as(IfExprSyntax.self) {
            // Else-if adds a branch but does not add another nesting penalty.
            alternativeScore = scoreBranch(nextBranch, nesting: nesting, functionName: functionName) - nesting
        } else {
            alternativeScore = 1 + score(Syntax(alternative), nesting: nesting + 1, functionName: functionName)
        }
        return 1 + nesting + condition + body + alternativeScore
    }

    private static func flatIncrement(_ node: Syntax, functionName: String) -> Int {
        if let statement = node.as(BreakStmtSyntax.self), statement.label != nil {
            return 1
        }
        if let statement = node.as(ContinueStmtSyntax.self), statement.label != nil {
            return 1
        }
        if let call = node.as(FunctionCallExprSyntax.self), !functionName.isEmpty {
            let name = call.calledExpression.trimmedDescription
            return name == functionName || name == "self.\(functionName)" ? 1 : 0
        }
        return 0
    }

    private static func scoreSequence(_ sequence: SequenceExprSyntax, nesting: Int, functionName: String) -> Int {
        let elements = Array(sequence.elements)
        if let index = elements.firstIndex(where: { $0.is(UnresolvedTernaryExprSyntax.self) }),
           let ternary = elements[index].as(UnresolvedTernaryExprSyntax.self) {
            // The parser leaves ternaries unfolded; the false branch is right-associative.
            let condition = SequenceExprSyntax(elements: ExprListSyntax(elements.prefix(index)))
            let alternative = SequenceExprSyntax(elements: ExprListSyntax(elements.suffix(from: index + 1)))
            return 1 + nesting
                + score(Syntax(condition), nesting: nesting, functionName: functionName)
                + score(Syntax(ternary.thenExpression), nesting: nesting + 1, functionName: functionName)
                + score(Syntax(alternative), nesting: nesting + 1, functionName: functionName)
        }
        return booleanSequences(sequence) + elements.reduce(0) {
            $0 + score(Syntax($1), nesting: nesting, functionName: functionName)
        }
    }

    private static func booleanSequences(_ sequence: SequenceExprSyntax) -> Int {
        let operators = sequence.elements.compactMap { $0.as(BinaryOperatorExprSyntax.self)?.operator.text }
            .filter { $0 == "&&" || $0 == "||" }
        return zip(operators, [""] + operators).filter { $0 != $1 }.count
    }
}
