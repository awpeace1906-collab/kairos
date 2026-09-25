import SwiftUI

/// A content table. Mirrors `renderTable` in web/src/views/prose.js.
///
/// Every row — header included — is laid out by the same `WeightedColumns`
/// layout with the same weights, so the columns line up however the text in
/// any one row wraps. (Laying each row out as its own flexible HStack, as
/// before, sized every row's columns from that row's text alone.) On a phone,
/// tables of three or more columns become stacked row cards instead: the
/// first cell is the card's title and every other cell sits under its column
/// name, so nothing needs a sideways scroll.
struct TableBlock: View {
    let columns: [String]
    let rows: [[String]]
    @Environment(\.horizontalSizeClass) private var sizeClass

    /// Tables at least this wide become cards on a compact-width screen.
    static let stackColumns = 3

    var body: some View {
        let weights = Self.weights(columns: columns, rows: rows)
        if sizeClass == .compact && Self.shouldStack(columns: columns, rows: rows) {
            cards(count: weights.count)
        } else {
            grid(weights)
        }
    }

    /// Stack into row cards when there are three or more columns, or two where
    /// the second is running prose (averaging over 60 characters) — a label
    /// beside a paragraph leaves the paragraph a thin, very tall strip.
    /// Mirrors `shouldStackTable` in web/src/lib/richText.js.
    static func shouldStack(columns: [String], rows: [[String]]) -> Bool {
        let n = max(columns.count, rows.map(\.count).max() ?? 0, 1)
        if n >= stackColumns { return true }
        guard n == 2, !rows.isEmpty else { return false }
        let avg = CGFloat(rows.reduce(0) { $0 + ($1.count > 1 ? $1[1].count : 0) }) / CGFloat(rows.count)
        return avg > 60
    }

    /// Relative column widths: wordier columns get more room, damped by a
    /// square root. No column drops below 60% of an even share, nor below the
    /// width its longest word needs on a phone (~30 characters across, less cell padding), so
    /// "pneumothorax" never breaks mid-word. Same formula as
    /// `tableColumnWeights` in web/src/lib/richText.js.
    static let phoneLineChars: CGFloat = 30

    static func weights(columns: [String], rows: [[String]]) -> [CGFloat] {
        let n = max(columns.count, rows.map(\.count).max() ?? 0, 1)
        func cells(_ c: Int) -> [String] { rows.map { c < $0.count ? $0[c] : "" } }
        let raw: [CGFloat] = (0..<n).map { c in
            let all = [c < columns.count ? columns[c] : ""] + cells(c)
            let avg = CGFloat(all.reduce(0) { $0 + $1.count }) / CGFloat(all.count)
            return CGFloat(max(avg, 4)).squareRoot()
        }
        let wordMin: [CGFloat] = (0..<n).map { c in
            let longest = cells(c).flatMap { $0.split(whereSeparator: \.isWhitespace) }.map(\.count).max() ?? 0
            return min(CGFloat(longest + 3) / phoneLineChars, 0.45)
        }
        // Pin any column that would fall under its minimum at that minimum,
        // share what is left among the others in proportion, and repeat until
        // stable — so a minimum is never undone by the final normalization.
        let floor = 0.6 / CGFloat(n)
        let mins = wordMin.map { max($0, floor) }
        let minSum = mins.reduce(0, +)
        if minSum >= 1 { return mins.map { $0 / minSum } }
        var pinned = Set<Int>()
        var w = raw
        for _ in 0...n {
            let free = (0..<n).filter { !pinned.contains($0) }
            let rest = 1 - pinned.reduce(0) { $0 + mins[$1] }
            let freeRaw = free.reduce(0) { $0 + raw[$1] }
            w = (0..<n).map { pinned.contains($0) ? mins[$0] : raw[$0] / freeRaw * rest }
            let under = free.filter { w[$0] < mins[$0] }
            if under.isEmpty { break }
            pinned.formUnion(under)
        }
        return w
    }

    private func cell(_ row: [String], _ i: Int) -> String { i < row.count ? row[i] : "" }

    @ViewBuilder private func grid(_ weights: [CGFloat]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if !columns.isEmpty {
                WeightedColumns(weights: weights, spacing: 12) {
                    ForEach(0..<weights.count, id: \.self) { i in
                        Text(cell(columns, i).uppercased()).font(Theme.mono(11)).tracking(0.4)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 6)
                Divider()
            }
            ForEach(Array(rows.enumerated()), id: \.offset) { idx, row in
                WeightedColumns(weights: weights, spacing: 12) {
                    ForEach(0..<weights.count, id: \.self) { i in
                        RichText(cell(row, i)).font(Theme.callout)
                    }
                }
                .padding(.vertical, 6)
                if idx < rows.count - 1 { Divider().opacity(0.4) }
            }
        }
    }

    @ViewBuilder private func cards(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                VStack(alignment: .leading, spacing: 7) {
                    RichText(cell(row, 0)).font(Theme.callout).fontWeight(.semibold)
                    ForEach(1..<count, id: \.self) { i in
                        let value = cell(row, i)
                        if !value.isEmpty {
                            // Label beside value: short values stay on one
                            // line, long ones wrap in their own column.
                            // A two-column card is a title plus its text.
                            if cell(columns, i).isEmpty || count == 2 {
                                RichText(value).font(Theme.callout)
                            } else {
                                WeightedColumns(weights: [0.34, 0.66], spacing: 10) {
                                    Text(cell(columns, i).uppercased()).font(Theme.mono(10.5)).tracking(0.4)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                    RichText(value).font(Theme.callout)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 0.5))
            }
        }
    }
}

/// Lays its subviews out left to right, each given a fixed share of the
/// available width. Two rows given the same weights always align.
struct WeightedColumns: Layout {
    let weights: [CGFloat]
    var spacing: CGFloat = 12

    private func widths(_ total: CGFloat, count: Int) -> [CGFloat] {
        let usable = max(total - spacing * CGFloat(max(count - 1, 0)), 0)
        return (0..<count).map { i in usable * (i < weights.count ? weights[i] : 0) }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let total = proposal.width ?? 320
        let w = widths(total, count: subviews.count)
        let height = subviews.indices.map { i in
            subviews[i].sizeThatFits(ProposedViewSize(width: w[i], height: nil)).height
        }.max() ?? 0
        return CGSize(width: total, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let w = widths(bounds.width, count: subviews.count)
        var x = bounds.minX
        for i in subviews.indices {
            subviews[i].place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                              proposal: ProposedViewSize(width: w[i], height: nil))
            x += w[i] + spacing
        }
    }
}
