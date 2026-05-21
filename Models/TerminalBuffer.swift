import Foundation

struct TerminalLine: Identifiable {
    let id: UUID
    var attributedString: AttributedString
    var rawText: String
    var timestamp: Date

    init(id: UUID = UUID(), attributedString: AttributedString, rawText: String, timestamp: Date = Date()) {
        self.id = id
        self.attributedString = attributedString
        self.rawText = rawText
        self.timestamp = timestamp
    }
}

@Observable
final class TerminalBuffer {
    var lines: [TerminalLine] = []
    var cursorPosition: CursorPosition = CursorPosition()
    var scrollbackLimit: Int = 10000
    var columns: Int = 80
    var rows: Int = 24

    struct CursorPosition {
        var row: Int = 0
        var col: Int = 0
    }

    private var rawBuffer: String = ""
    private var pendingData: String = ""

    func appendOutput(_ text: String) {
        let combined = pendingData + text
        pendingData = ""

        // Buffer incomplete ANSI escape sequences at end of chunk
        if let lastESC = combined.lastIndex(of: "\u{1B}") {
            let afterESC = combined.index(after: lastESC)
            if afterESC < combined.endIndex {
                // Check if the escape sequence is complete
                var i = afterESC
                var foundOpen = false
                var foundEnd = false
                while i < combined.endIndex {
                    let ch = combined[i]
                    if ch == "[" && !foundOpen {
                        foundOpen = true
                    } else if foundOpen && ch.isLetter {
                        foundEnd = true
                        break
                    } else if !foundOpen && ch != "[" {
                        break // Not a CSI sequence
                    }
                    i = combined.index(after: i)
                }
                if !foundEnd {
                    // Incomplete escape sequence - buffer it
                    pendingData = String(combined[lastESC...])
                    let complete = String(combined[..<lastESC])
                    if !complete.isEmpty {
                        processCompleteOutput(complete)
                    }
                    return
                }
            }
        }

        processCompleteOutput(combined)
    }

    private func processCompleteOutput(_ text: String) {
        rawBuffer += text
        let parsedLines = ANSIParser.parse(text, columns: columns)
        lines.append(contentsOf: parsedLines)

        if lines.count > scrollbackLimit {
            let excess = lines.count - scrollbackLimit
            lines.removeFirst(excess)
        }
    }

    func flush() {
        if !pendingData.isEmpty {
            processCompleteOutput(pendingData)
            pendingData = ""
        }
    }

    func clear() {
        lines.removeAll()
        rawBuffer = ""
        cursorPosition = CursorPosition()
    }

    var fullText: String {
        lines.map(\.rawText).joined(separator: "\n")
    }

    var fullAttributedString: AttributedString {
        var result = AttributedString()
        for (index, line) in lines.enumerated() {
            result.append(line.attributedString)
            if index < lines.count - 1 {
                result.append(AttributedString("\n"))
            }
        }
        return result
    }

    var lineCount: Int {
        lines.count
    }

    func resize(columns: Int, rows: Int) {
        self.columns = columns
        self.rows = rows
    }
}
