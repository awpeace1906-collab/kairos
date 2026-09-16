import SwiftUI

/// Renders a `Diagram` — an original declarative vector figure — with SwiftUI
/// `Canvas`, the same approach `NomogramView` uses for calculator plots. Mirrors
/// the web `renderDiagram()` in content.js; see common.schema.json#/$defs/diagram.
///
/// Content never carries raw hex: shapes name a semantic token (`tissue`,
/// `danger`, …) and each client maps it to its own palette, so one authored
/// figure stays legible in light and dark.
struct DiagramView: View {
    let diagram: Diagram
    @Environment(\.colorScheme) private var scheme

    private var vb: (x: Double, y: Double, w: Double, h: Double) {
        let b = diagram.viewBox
        guard b.count == 4, b[2] > 0, b[3] > 0 else { return (0, 0, 1, 1) }
        return (b[0], b[1], b[2], b[3])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title = diagram.title {
                Text(title.uppercased())
                    .font(Theme.mono(10))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }
            Canvas { ctx, size in draw(&ctx, size: size) }
                .aspectRatio(vb.w / vb.h, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel(diagram.title ?? diagram.caption ?? "clinical diagram")
            if let caption = diagram.caption {
                Text(caption)
                    .font(Theme.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        // uniform scale + centering, equivalent to SVG preserveAspectRatio="xMidYMid meet"
        let s = min(size.width / vb.w, size.height / vb.h)
        let ox = (size.width - vb.w * s) / 2 - vb.x * s
        let oy = (size.height - vb.h * s) / 2 - vb.y * s
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: ox + x * s, y: oy + y * s)
        }

        for shape in diagram.shapes {
            let lw = (shape.strokeWidth ?? 1.5) * s
            var style = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            if shape.dash == true { style.dash = [5 * s, 4 * s] }
            let fillColor = color(shape.fill)
            let strokeColor = color(shape.stroke)
            let opacity = shape.opacity ?? 1

            switch shape.kind {
            case "path":
                guard let d = shape.d, let p = SVGPath.parse(d, transform: pt) else { break }
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "line":
                guard let a = shape.from, let b = shape.to, a.count == 2, b.count == 2 else { break }
                var p = Path(); p.move(to: pt(a[0], a[1])); p.addLine(to: pt(b[0], b[1]))
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "polyline":
                guard let pts = shape.points, pts.count > 1 else { break }
                var p = Path()
                p.move(to: pt(pts[0][0], pts[0][1]))
                for q in pts.dropFirst() where q.count == 2 { p.addLine(to: pt(q[0], q[1])) }
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "rect":
                guard let a = shape.at, let sz = shape.size, a.count == 2, sz.count == 2 else { break }
                let rect = CGRect(origin: pt(a[0], a[1]), size: CGSize(width: sz[0] * s, height: sz[1] * s))
                let p = Path(roundedRect: rect, cornerRadius: (shape.rx ?? 0) * s)
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "circle":
                guard let a = shape.at, a.count == 2, let r = shape.r else { break }
                let c = pt(a[0], a[1]), rr = r * s
                let p = Path(ellipseIn: CGRect(x: c.x - rr, y: c.y - rr, width: rr * 2, height: rr * 2))
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "ellipse":
                guard let a = shape.at, a.count == 2, let rx = shape.rx, let ry = shape.ry else { break }
                let c = pt(a[0], a[1])
                let p = Path(ellipseIn: CGRect(x: c.x - rx * s, y: c.y - ry * s, width: rx * 2 * s, height: ry * 2 * s))
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "arrow":
                guard let a = shape.from, let b = shape.to, a.count == 2, b.count == 2,
                      let st = strokeColor else { break }
                let p1 = pt(a[0], a[1]), p2 = pt(b[0], b[1])
                let ang = atan2(p2.y - p1.y, p2.x - p1.x)
                let head = 7 * s, halfW = 3.6 * s
                let back = CGPoint(x: p2.x - head * cos(ang), y: p2.y - head * sin(ang))
                var shaft = Path(); shaft.move(to: p1); shaft.addLine(to: back)
                ctx.stroke(shaft, with: .color(st.opacity(opacity)), style: style)
                var tip = Path()
                tip.move(to: p2)
                tip.addLine(to: CGPoint(x: back.x + halfW * sin(ang), y: back.y - halfW * cos(ang)))
                tip.addLine(to: CGPoint(x: back.x - halfW * sin(ang), y: back.y + halfW * cos(ang)))
                tip.closeSubpath()
                ctx.fill(tip, with: .color(st.opacity(opacity)))

            case "text":
                guard let a = shape.at, a.count == 2, let str = shape.text else { break }
                let fs = (shape.fontSize ?? 11) * s
                var t = Text(str).font(.system(size: fs, weight: shape.weight == "bold" ? .semibold : .regular))
                t = t.foregroundColor((color(shape.fill) ?? color("text")!).opacity(opacity))
                let anchor: UnitPoint = switch shape.anchor {
                    case "middle": .center
                    case "end": .trailing
                    default: .leading
                }
                // SVG text y is the baseline; Canvas anchors on the box, so nudge up.
                ctx.draw(t, at: CGPoint(x: pt(a[0], a[1]).x, y: pt(a[0], a[1]).y - fs * 0.35), anchor: anchor)

            default:
                break
            }
        }
    }

    /// Semantic token -> palette colour. Mirrors DIAGRAM_TOKENS in content.js and
    /// the --dg-* custom properties in styles.css.
    private func color(_ token: String?) -> Color? {
        guard let token else { return nil }
        let dark = scheme == .dark
        switch token {
        case "outline": return dark ? Color(hex: 0xC9C5D0) : Color(hex: 0x3A3742)
        case "surface": return dark ? Color(hex: 0x242329) : Color(hex: 0xFBFAF8)
        case "tissue":  return dark ? Color(hex: 0x4A3B36) : Color(hex: 0xF0DDD2)
        case "bone":    return dark ? Color(hex: 0x4A473F) : Color(hex: 0xEAE6DC)
        case "lumen":   return dark ? Color(hex: 0x33404A) : Color(hex: 0xDFE6EA)
        case "muscle":  return dark ? Color(hex: 0x8A5145) : Color(hex: 0xCF9384)
        case "vessel":  return dark ? Color(hex: 0x9D6B96) : Color(hex: 0x8C5A86)
        case "accent":  return Theme.severityColor("moderate")
        case "danger":  return Theme.severityColor("high")
        case "warning": return Theme.severityColor("moderate")
        case "good":    return Theme.severityColor("low")
        case "muted":   return .secondary
        case "text":    return .primary
        default:        return nil
        }
    }
}

private extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Minimal SVG path-data parser — enough for hand-authored clinical figures:
/// M/m L/l H/h V/v C/c Q/q Z/z. Arcs are deliberately unsupported (approximate
/// with cubics) so this stays small and dependency-free.
enum SVGPath {
    static func parse(_ d: String, transform: (Double, Double) -> CGPoint) -> Path? {
        var path = Path()
        var cur = CGPoint.zero          // current point, in the diagram's own coords
        var start = CGPoint.zero
        var i = d.startIndex
        var cmd: Character = " "
        var any = false

        func nextNumber() -> Double? {
            while i < d.endIndex, d[i] == " " || d[i] == "," || d[i] == "\n" || d[i] == "\t" { i = d.index(after: i) }
            var s = ""
            if i < d.endIndex, d[i] == "-" || d[i] == "+" { s.append(d[i]); i = d.index(after: i) }
            while i < d.endIndex, d[i].isNumber || d[i] == "." { s.append(d[i]); i = d.index(after: i) }
            if i < d.endIndex, d[i] == "e" || d[i] == "E" {   // scientific notation
                s.append(d[i]); i = d.index(after: i)
                if i < d.endIndex, d[i] == "-" || d[i] == "+" { s.append(d[i]); i = d.index(after: i) }
                while i < d.endIndex, d[i].isNumber { s.append(d[i]); i = d.index(after: i) }
            }
            return Double(s)
        }

        while i < d.endIndex {
            let ch = d[i]
            if ch.isLetter {
                cmd = ch
                i = d.index(after: i)
            } else if ch == " " || ch == "," || ch == "\n" || ch == "\t" {
                i = d.index(after: i)
                continue
            }

            let rel = cmd.isLowercase
            switch Character(cmd.uppercased()) {
            case "M":
                guard let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                cur = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                start = cur
                path.move(to: transform(cur.x, cur.y))
                any = true
                // implicit subsequent pairs are treated as L, per SVG spec
                cmd = rel ? "l" : "L"
            case "L":
                guard let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                cur = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                path.addLine(to: transform(cur.x, cur.y))
            case "H":
                guard let x = nextNumber() else { return any ? path : nil }
                cur = CGPoint(x: rel ? cur.x + x : x, y: cur.y)
                path.addLine(to: transform(cur.x, cur.y))
            case "V":
                guard let y = nextNumber() else { return any ? path : nil }
                cur = CGPoint(x: cur.x, y: rel ? cur.y + y : y)
                path.addLine(to: transform(cur.x, cur.y))
            case "C":
                guard let x1 = nextNumber(), let y1 = nextNumber(),
                      let x2 = nextNumber(), let y2 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                let c1 = rel ? CGPoint(x: cur.x + x1, y: cur.y + y1) : CGPoint(x: x1, y: y1)
                let c2 = rel ? CGPoint(x: cur.x + x2, y: cur.y + y2) : CGPoint(x: x2, y: y2)
                let end = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                path.addCurve(to: transform(end.x, end.y),
                              control1: transform(c1.x, c1.y),
                              control2: transform(c2.x, c2.y))
                cur = end
            case "Q":
                guard let x1 = nextNumber(), let y1 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                let c = rel ? CGPoint(x: cur.x + x1, y: cur.y + y1) : CGPoint(x: x1, y: y1)
                let end = rel ? CGPoint(x: cur.x + x, y: cur.y + y) : CGPoint(x: x, y: y)
                path.addQuadCurve(to: transform(end.x, end.y), control: transform(c.x, c.y))
                cur = end
            case "Z":
                path.closeSubpath()
                cur = start
            default:
                // unsupported command (e.g. A) — bail out rather than draw garbage
                return any ? path : nil
            }
        }
        return any ? path : nil
    }
}
