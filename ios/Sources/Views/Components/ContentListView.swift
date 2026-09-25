import SwiftUI

/// Renders a content list, nested to any depth the validator allows (3).
///
/// Mirrors `renderList` / `listItem` in web/src/views/content.js — keep the
/// two in sync. The markers change per level rather than relying on
/// indentation alone: on a phone held at arm's length, horizontal space is
/// the scarce resource, so depth has to read from the glyph.
///
/// The struct recurses through its own `body`, which is safe here because
/// validate.mjs caps nesting at three levels.
struct ContentListView: View {
    let items: [ListItem]
    let ordered: Bool
    var depth: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                VStack(alignment: .leading, spacing: 4) {
                    // Marker in its own column, so a wrapped line hangs under
                    // the text rather than running back under the bullet.
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(marker(index))
                            .frame(minWidth: ordered ? 16 : 8, alignment: .leading)
                        Self.leadText(item.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if let children = item.items, !children.isEmpty {
                        ContentListView(
                            items: children,
                            ordered: item.ordered,
                            depth: depth + 1
                        )
                        .padding(.leading, 14)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    /// Ordered levels alternate 1. / a. / i. ; unordered levels • / ◦ / ▪.
    private func marker(_ index: Int) -> String {
        guard ordered else {
            switch depth {
            case 0: return "•"
            case 1: return "◦"
            default: return "▪"
            }
        }
        switch depth {
        case 0:
            return "\(index + 1)."
        case 1:
            // 26 letters is far more than any real sub-step list; wrap rather
            // than crash on the absurd case.
            let letter = Character(UnicodeScalar(97 + index % 26)!)
            return "\(letter)."
        default:
            return "\(Self.roman(index + 1))."
        }
    }

    private static func roman(_ n: Int) -> String {
        let table: [(Int, String)] = [
            (10, "x"), (9, "ix"), (5, "v"), (4, "iv"), (1, "i"),
        ]
        var value = n
        var out = ""
        for (amount, numeral) in table {
            while value >= amount {
                out += numeral
                value -= amount
            }
        }
        return out.isEmpty ? "i" : out
    }

    /// A "Term: the rest of the sentence" entry gets its lead term bolded —
    /// purely presentational, and degrades to plain text for anything that
    /// isn't shaped that way. Short lead-in only (<= 7 words) so a colon
    /// appearing mid-sentence in ordinary prose isn't misread as a label.
    static func line(marker: String, text: String) -> Text {
        Text("\(marker) ") + leadText(text)
    }

    static func leadText(_ text: String) -> Text {
        guard let colonRange = text.range(of: ": ") else { return Text(text) }
        let leadLength = text.distance(from: text.startIndex, to: colonRange.lowerBound)
        guard leadLength >= 2, leadLength <= 50 else { return Text(text) }
        let lead = String(text[text.startIndex..<colonRange.lowerBound])
        guard lead.split(separator: " ").count <= 7 else { return Text(text) }
        let rest = String(text[colonRange.upperBound...])
        return Text("\(lead):").fontWeight(.semibold) + Text(" \(rest)")
    }
}
