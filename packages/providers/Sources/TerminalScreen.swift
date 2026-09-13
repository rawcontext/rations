import Foundation

struct TerminalScreen {
    private var cells = Array(repeating: Array(repeating: " ", count: 180), count: 60)
    private var row = 0
    private var column = 0
    private var saved = (row: 0, column: 0)

    var text: String { cells.map { $0.joined().trimmingCharacters(in: .whitespaces) }.joined(separator: "\n") }

    mutating func consume(_ data: Data) {
        guard let text = String(data: data, encoding: .utf8) else { return }
        let scalars = Array(text.unicodeScalars)
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            index += 1
            if scalar.value == 27 { escape(scalars, index: &index) } else { put(scalar) }
        }
    }

    private mutating func put(_ scalar: Unicode.Scalar) {
        switch scalar.value {
        case 13: column = 0
        case 10: row += 1; scrollIfNeeded()
        case 8: column = max(0, column - 1)
        case 9: column = min(179, (column / 8 + 1) * 8)
        case 0..<32, 127: break
        default:
            if column >= 180 { column = 0; row += 1; scrollIfNeeded() }
            cells[row][column] = String(scalar)
            column += scalar.properties.isEmojiPresentation ? 2 : 1
        }
    }

    private mutating func scrollIfNeeded() {
        if row >= cells.count { cells.removeFirst(); cells.append(Array(repeating: " ", count: 180)); row = 59 }
        row = max(0, row)
    }

    private mutating func escape(_ scalars: [Unicode.Scalar], index: inout Int) {
        guard index < scalars.count else { return }
        let start = scalars[index]
        index += 1
        if start == "[" {
            var parameters = ""
            while index < scalars.count {
                let value = scalars[index]
                index += 1
                if (64...126).contains(value.value) { control(String(value), parameters: parameters); return }
                parameters += String(value)
            }
        } else if start == "]" {
            skipTitle(scalars, index: &index)
        } else if start == "7" { saved = (row, column) } else if start == "8" { row = saved.row; column = saved.column }
    }

    private func skipTitle(_ scalars: [Unicode.Scalar], index: inout Int) {
        while index < scalars.count {
            let value = scalars[index].value
            index += 1
            if value == 7 { return }
            if value == 27, index < scalars.count, scalars[index] == "\\" { index += 1; return }
        }
    }

    private mutating func control(_ command: String, parameters: String) {
        let values = parameters.split(separator: ";", omittingEmptySubsequences: false).map { Int($0) ?? 0 }
        let first = values.first ?? 0
        if ["A", "B", "C", "D", "G", "H", "f"].contains(command) {
            move(command, values: values)
        } else if command == "J" {
            if first == 2 || first == 3 {
                cells = Array(repeating: Array(repeating: " ", count: 180), count: 60)
            } else {
                clearLine(from: column, through: 179)
                for index in (row + 1)..<60 { cells[index] = Array(repeating: " ", count: 180) }
            }
        } else if command == "K" {
            clearLine(from: first == 0 ? column : 0, through: first == 1 ? column : 179)
        }
    }

    private mutating func move(_ command: String, values: [Int]) {
        let amount = max(1, values.first ?? 1)
        switch command {
        case "A": row -= amount
        case "B": row += amount
        case "C": column += amount
        case "D": column -= amount
        case "G": column = amount - 1
        default: row = amount - 1; column = max(1, values.dropFirst().first ?? 1) - 1
        }
        row = min(59, max(0, row))
        column = min(179, max(0, column))
    }

    private mutating func clearLine(from start: Int, through end: Int) {
        guard start <= end else { return }
        for index in max(0, start)...min(179, end) { cells[row][index] = " " }
    }
}
