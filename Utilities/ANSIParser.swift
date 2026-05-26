import SwiftUI

struct ANSIParser {
    enum ANSIColor: Equatable {
        case black, red, green, yellow, blue, magenta, cyan, white
        case brightBlack, brightRed, brightGreen, brightYellow
        case brightBlue, brightMagenta, brightCyan, brightWhite
        case rgb(UInt8, UInt8, UInt8)
        case `default`

        var color: Color {
            switch self {
            case .black: return Color(red: 0, green: 0, blue: 0)
            case .red: return Color(red: 0.8, green: 0, blue: 0)
            case .green: return Color(red: 0, green: 0.8, blue: 0)
            case .yellow: return Color(red: 0.8, green: 0.8, blue: 0)
            case .blue: return Color(red: 0, green: 0, blue: 0.8)
            case .magenta: return Color(red: 0.8, green: 0, blue: 0.8)
            case .cyan: return Color(red: 0, green: 0.8, blue: 0.8)
            case .white: return Color(red: 0.8, green: 0.8, blue: 0.8)
            case .brightBlack: return Color(red: 0.5, green: 0.5, blue: 0.5)
            case .brightRed: return Color(red: 1, green: 0, blue: 0)
            case .brightGreen: return Color(red: 0, green: 1, blue: 0)
            case .brightYellow: return Color(red: 1, green: 1, blue: 0)
            case .brightBlue: return Color(red: 0, green: 0, blue: 1)
            case .brightMagenta: return Color(red: 1, green: 0, blue: 1)
            case .brightCyan: return Color(red: 0, green: 1, blue: 1)
            case .brightWhite: return Color(red: 1, green: 1, blue: 1)
            case .rgb(let r, let g, let b):
                return Color(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
            case .default: return Color.primary
            }
        }
    }

    struct ANSISpan {
        var text: String
        var foreground: ANSIColor = .default
        var background: ANSIColor = .default
        var isBold: Bool = false
        var isItalic: Bool = false
        var isUnderline: Bool = false
        var isDim: Bool = false
        var isBlink: Bool = false
        var isReverse: Bool = false
        var isStrikethrough: Bool = false
    }

    static func parse(_ input: String, columns: Int = 80) -> [TerminalLine] {
        var lines: [TerminalLine] = []
        let normalized = input
            .replacingOccurrences(of: "\r\n", with: "\n")

        // Handle carriage returns: \r overwrites the current line
        var currentLine = ""
        for char in normalized {
            if char == "\n" {
                lines.append(buildTerminalLine(currentLine))
                currentLine = ""
            } else if char == "\r" {
                // Carriage return: discard current line content, start overwrite
                currentLine = ""
            } else {
                currentLine.append(char)
            }
        }
        if !currentLine.isEmpty {
            lines.append(buildTerminalLine(currentLine))
        }

        return lines
    }

    private static func buildTerminalLine(_ text: String) -> TerminalLine {
        let spans = parseANSI(text)
        let attributedString = buildAttributedString(from: spans)
        let rawText = spans.map(\.text).joined()
        return TerminalLine(attributedString: attributedString, rawText: rawText)
    }

    static func parseANSI(_ input: String) -> [ANSISpan] {
        var spans: [ANSISpan] = []
        var currentSpan = ANSISpan(text: "")
        var i = input.startIndex

        while i < input.endIndex {
            if input[i] == "\u{1B}" {
                if !currentSpan.text.isEmpty {
                    spans.append(currentSpan)
                    currentSpan = ANSISpan(text: "")
                }

                let nextIndex = input.index(after: i)
                if nextIndex < input.endIndex && input[nextIndex] == "[" {
                    var escapeEnd = input.index(after: nextIndex)
                    while escapeEnd < input.endIndex && !input[escapeEnd].isLetter {
                        escapeEnd = input.index(after: escapeEnd)
                    }

                    if escapeEnd < input.endIndex {
                        let terminator = input[escapeEnd]
                        let escapeSequence = input[input.index(after: nextIndex)..<escapeEnd]

                        if terminator == "m" {
                            applySGR(String(escapeSequence), to: &currentSpan)
                        }

                        i = input.index(after: escapeEnd)
                        continue
                    }
                }
            } else {
                currentSpan.text.append(input[i])
            }
            i = input.index(after: i)
        }

        if !currentSpan.text.isEmpty {
            spans.append(currentSpan)
        }

        return spans
    }

    private static func applySGR(_ sequence: String, to span: inout ANSISpan) {
        let codes = sequence.split(separator: ";").compactMap { Int($0) }

        var i = 0
        while i < codes.count {
            let code = codes[i]
            switch code {
            case 0:
                span = ANSISpan(text: span.text)
            case 1: span.isBold = true
            case 2: span.isDim = true
            case 3: span.isItalic = true
            case 4: span.isUnderline = true
            case 5, 6: span.isBlink = true
            case 7: span.isReverse = true
            case 9: span.isStrikethrough = true
            case 22: span.isBold = false; span.isDim = false
            case 23: span.isItalic = false
            case 24: span.isUnderline = false
            case 25: span.isBlink = false
            case 27: span.isReverse = false
            case 29: span.isStrikethrough = false
            case 30: span.foreground = .black
            case 31: span.foreground = .red
            case 32: span.foreground = .green
            case 33: span.foreground = .yellow
            case 34: span.foreground = .blue
            case 35: span.foreground = .magenta
            case 36: span.foreground = .cyan
            case 37: span.foreground = .white
            case 38:
                if i + 4 < codes.count && codes[i + 1] == 2 {
                    span.foreground = .rgb(UInt8(codes[i + 2]), UInt8(codes[i + 3]), UInt8(codes[i + 4]))
                    i += 4
                }
            case 39: span.foreground = .default
            case 40: span.background = .black
            case 41: span.background = .red
            case 42: span.background = .green
            case 43: span.background = .yellow
            case 44: span.background = .blue
            case 45: span.background = .magenta
            case 46: span.background = .cyan
            case 47: span.background = .white
            case 48:
                if i + 4 < codes.count && codes[i + 1] == 2 {
                    span.background = .rgb(UInt8(codes[i + 2]), UInt8(codes[i + 3]), UInt8(codes[i + 4]))
                    i += 4
                }
            case 49: span.background = .default
            case 90: span.foreground = .brightBlack
            case 91: span.foreground = .brightRed
            case 92: span.foreground = .brightGreen
            case 93: span.foreground = .brightYellow
            case 94: span.foreground = .brightBlue
            case 95: span.foreground = .brightMagenta
            case 96: span.foreground = .brightCyan
            case 97: span.foreground = .brightWhite
            case 100: span.background = .brightBlack
            case 101: span.background = .brightRed
            case 102: span.background = .brightGreen
            case 103: span.background = .brightYellow
            case 104: span.background = .brightBlue
            case 105: span.background = .brightMagenta
            case 106: span.background = .brightCyan
            case 107: span.background = .brightWhite
            default: break
            }
            i += 1
        }
    }

    private static func buildAttributedString(from spans: [ANSISpan]) -> AttributedString {
        var result = AttributedString()

        for span in spans {
            var attributed = AttributedString(span.text)

            var fgColor = span.foreground
            var bgColor = span.background

            if span.isReverse {
                swap(&fgColor, &bgColor)
            }

            if fgColor != .default {
                attributed.foregroundColor = fgColor.color
            }
            if bgColor != .default {
                attributed.backgroundColor = bgColor.color
            }
            if span.isBold && span.isItalic {
                attributed.font = .system(.body, design: .monospaced).bold().italic()
            } else if span.isBold {
                attributed.font = .system(.body, design: .monospaced).bold()
            } else if span.isItalic {
                attributed.font = .system(.body, design: .monospaced).italic()
            } else {
                attributed.font = .system(.body, design: .monospaced)
            }
            if span.isUnderline {
                attributed.underlineStyle = .single
            }
            if span.isStrikethrough {
                attributed.strikethroughStyle = .single
            }

            result.append(attributed)
        }

        return result
    }
}
