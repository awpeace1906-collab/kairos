import SwiftUI

/// The Kairos text format — the small amount of structure a prose field may
/// carry. Content stays plain strings; the renderer reads:
///
///   blank line          -> new paragraph
///   "- text"            -> bullet ("• " also accepted)
///   "1. text"           -> numbered item ("1)" also accepted)
///   two-space indent    -> nested one level under the previous item
///   any other newline   -> line break inside the paragraph
///   "LEVEL: text"       -> an ALL-CAPS lead label on a line is shown bold
///
/// Mirrors web/src/lib/richText.js (parser, tested in tools/test.mjs) and
/// web/src/views/prose.js (renderer) — keep them in sync.
enum RichTextFormat {
    enum Block: Equatable {
        case paragraph([String])
        case list(ordered: Bool, items: [Item])
    }

    struct Item: Equatable {
        var text: String
        var ordered = false
        var items: [Item] = []
    }

    static func parse(_ text: String) -> [Block] {
        var blocks: [Block] = []
        var inBlock = false // false after a blank line: the next line starts a new block
        let lines = text.replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        for raw in lines {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { inBlock = false; continue }
            let indent = raw.prefix { $0 == " " }.count

            if let (ordered, body) = listMarker(trimmed) {
                let item = Item(text: body)
                if indent >= 2, inBlock, case .list(let o, var items)? = blocks.last, !items.isEmpty {
                    if items[items.count - 1].items.isEmpty { items[items.count - 1].ordered = ordered }
                    items[items.count - 1].items.append(item)
                    blocks[blocks.count - 1] = .list(ordered: o, items: items)
                    continue
                }
                if inBlock, case .list(let o, var items)? = blocks.last, o == ordered {
                    items.append(item)
                    blocks[blocks.count - 1] = .list(ordered: o, items: items)
                } else {
                    blocks.append(.list(ordered: ordered, items: [item]))
                }
                inBlock = true
                continue
            }

            // A plain line: an indented one continues the last list item;
            // otherwise it breaks the line in the current paragraph, or starts one.
            if inBlock, indent >= 2, case .list(let o, var items)? = blocks.last {
                let last = items.count - 1
                if items[last].items.isEmpty {
                    items[last].text += " " + trimmed
                } else {
                    items[last].items[items[last].items.count - 1].text += " " + trimmed
                }
                blocks[blocks.count - 1] = .list(ordered: o, items: items)
                continue
            }
            if inBlock, case .paragraph(var ls)? = blocks.last {
                ls.append(trimmed)
                blocks[blocks.count - 1] = .paragraph(ls)
            } else {
                blocks.append(.paragraph([trimmed]))
            }
            inBlock = true
        }
        return blocks
    }

    /// "- x" / "• x" -> (false, x); "12. x" / "3) x" -> (true, x).
    private static func listMarker(_ line: String) -> (Bool, String)? {
        if line.hasPrefix("- ") || line.hasPrefix("• ") {
            return (false, String(line.dropFirst(2)).trimmingCharacters(in: .whitespaces))
        }
        let digits = line.prefix { $0.isASCII && $0.isNumber }
        guard (1...2).contains(digits.count) else { return nil }
        let rest = line.dropFirst(digits.count)
        guard let mark = rest.first, mark == "." || mark == ")",
              rest.dropFirst().first == " " else { return nil }
        return (true, String(rest.dropFirst(2)).trimmingCharacters(in: .whitespaces))
    }

    /// "LEVEL: rest" -> ("LEVEL:", "rest") for an ALL-CAPS label of at most six
    /// words; nil otherwise, so an ordinary sentence with a colon stays plain.
    static func leadLabel(_ line: String) -> (String, String)? {
        // A label alone on its line ("POSITION:") heads the list below it.
        let lead: String
        let rest: String
        if line.hasSuffix(":"), !line.dropLast().contains(":") {
            lead = String(line.dropLast())
            rest = ""
        } else if let r = line.range(of: ": ") {
            lead = String(line[..<r.lowerBound])
            rest = String(line[r.upperBound...])
        } else {
            return nil
        }
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ,'’()/&+-")
        guard (2...49).contains(lead.count),
              let first = lead.unicodeScalars.first,
              CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789").contains(first),
              lead.unicodeScalars.allSatisfy({ allowed.contains($0) }),
              lead.range(of: "[A-Z]{2}", options: .regularExpression) != nil,
              lead.split(separator: " ").count <= 6 else { return nil }
        return (lead + ":", rest)
    }
}

/// Renders a prose field in the Kairos text format. Font, color and weight
/// come from the environment, so call sites style it exactly as they styled
/// the plain `Text` it replaces.
struct RichText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        let blocks = RichTextFormat.parse(text)
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                switch block {
                case .paragraph(let lines):
                    Self.paragraph(lines)
                        .fixedSize(horizontal: false, vertical: true)
                case .list(let ordered, let items):
                    ContentListView(items: items.map(Self.listItem), ordered: ordered)
                }
            }
        }
    }

    private static func paragraph(_ lines: [String]) -> Text {
        lines.enumerated().reduce(Text("")) { acc, pair in
            let (i, line) = pair
            let piece: Text
            if let (label, rest) = RichTextFormat.leadLabel(line) {
                piece = rest.isEmpty ? Text(label).fontWeight(.semibold)
                    : Text(label).fontWeight(.semibold) + Text(" " + rest)
            } else {
                piece = Text(line)
            }
            return i == 0 ? piece : acc + Text("\n") + piece
        }
    }

    private static func listItem(_ item: RichTextFormat.Item) -> ListItem {
        ListItem(text: item.text, ordered: item.ordered,
                 items: item.items.isEmpty ? nil : item.items.map(listItem))
    }
}
