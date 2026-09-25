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

    private var hasPlate: Bool { diagram.image != nil }

    private var cardColor: Color {
        hasPlate ? Color(hex: 0xF7F5F0) : Color(.secondarySystemBackground)
    }

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
                .background(cardColor, in: RoundedRectangle(cornerRadius: 12))
                // A plate is ink on white, so its card stays light in every theme.
                // Setting the environment (not just the background) is what makes
                // `.primary` / `.secondary` inside the canvas resolve dark-on-light;
                // otherwise dark mode draws near-white labels onto white paper.
                .environment(\.colorScheme, hasPlate ? .light : scheme)
                .accessibilityLabel(diagram.title ?? diagram.caption ?? "clinical diagram")
            if let caption = diagram.caption {
                Text(caption)
                    .font(Theme.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let plate = diagram.image {
                Text(plate.credit)
                    .font(Theme.caption2)
                    .italic()
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 6)
    }

    // MARK: - drawing

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        // Every quantity below is explicitly CGFloat, and every content number
        // is converted at the boundary by `c`.
        //
        // This is not stylistic. Content coordinates arrive from JSON as Double
        // while CGSize/CGPoint are CGFloat, and Swift's implicit CGFloat<->Double
        // bridging resolves the mixed expressions on recent compilers but is
        // reported as "ambiguous use of operator '/'" by the Xcode 16 frontend
        // that CI builds with. Converting once at the boundary satisfies both
        // and costs nothing at runtime.
        func c(_ d: Double) -> CGFloat { CGFloat(d) }
        let vx = c(vb.x), vy = c(vb.y), vw = c(vb.w), vh = c(vb.h)

        // uniform scale + centering, equivalent to SVG preserveAspectRatio="xMidYMid meet"
        let s: CGFloat = min(size.width / vw, size.height / vh)
        let ox: CGFloat = (size.width - vw * s) / 2 - vx * s
        let oy: CGFloat = (size.height - vh * s) / 2 - vy * s
        func pt(_ x: Double, _ y: Double) -> CGPoint {
            CGPoint(x: ox + c(x) * s, y: oy + c(y) * s)
        }

        // Background plate first, so every shape draws on top of it — in the
        // plate's own pixel coordinates, which is what keeps the overlay
        // registered to the anatomy. Canvas clips to its bounds, so the viewBox
        // acts as a crop window. A missing plate (an older binary receiving a
        // newer module over the air) degrades to the overlay alone.
        if let plate = diagram.image, let ui = ContentAssets.image(plate.src) {
            let at = (plate.at?.count == 2) ? plate.at! : [0, 0]
            let origin = pt(at[0], at[1])
            let rect = CGRect(x: origin.x, y: origin.y,
                              width: c(plate.width) * s, height: c(plate.height) * s)
            ctx.draw(Image(uiImage: ui), in: rect)
        }

        for shape in diagram.shapes {
            let lw: CGFloat = c(shape.strokeWidth ?? 1.5) * s
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
                let rect = CGRect(origin: pt(a[0], a[1]),
                                  size: CGSize(width: c(sz[0]) * s, height: c(sz[1]) * s))
                let p = Path(roundedRect: rect, cornerRadius: c(shape.rx ?? 0) * s)
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "circle":
                guard let a = shape.at, a.count == 2, let r = shape.r else { break }
                let center = pt(a[0], a[1])
                let rr: CGFloat = c(r) * s
                let p = Path(ellipseIn: CGRect(x: center.x - rr, y: center.y - rr,
                                               width: rr * 2, height: rr * 2))
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "ellipse":
                guard let a = shape.at, a.count == 2, let rx = shape.rx, let ry = shape.ry else { break }
                let center = pt(a[0], a[1])
                let hx: CGFloat = c(rx) * s, hy: CGFloat = c(ry) * s
                let p = Path(ellipseIn: CGRect(x: center.x - hx, y: center.y - hy,
                                               width: hx * 2, height: hy * 2))
                if let f = fillColor { ctx.fill(p, with: .color(f.opacity(opacity))) }
                if let st = strokeColor { ctx.stroke(p, with: .color(st.opacity(opacity)), style: style) }

            case "arrow":
                guard let a = shape.from, let b = shape.to, a.count == 2, b.count == 2,
                      let st = strokeColor else { break }
                let p1 = pt(a[0], a[1]), p2 = pt(b[0], b[1])
                let ang: CGFloat = atan2(p2.y - p1.y, p2.x - p1.x)
                let head: CGFloat = 7 * s, halfW: CGFloat = 3.6 * s
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
                let fs: CGFloat = c(shape.fontSize ?? 11) * s
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

    /// Semantic token -> palette color. Mirrors DIAGRAM_TOKENS in content.js and
    /// the --dg-* custom properties in styles.css.
    private func color(_ token: String?) -> Color? {
        guard let token else { return nil }
        // Plates force the light palette (see `body`).
        let dark = scheme == .dark && !hasPlate
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
        // The parser works entirely in Double — the diagram's own coordinate
        // space — and converts only at the `transform` call. Using CGPoint here
        // would mix CGFloat with the Doubles coming out of `nextNumber`, which is
        // the same implicit-bridging pattern the Xcode 16 frontend rejects in
        // `draw` above.
        struct P { var x: Double; var y: Double }
        var cur = P(x: 0, y: 0)         // current point, in the diagram's own coords
        var start = P(x: 0, y: 0)
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
                cur = rel ? P(x: cur.x + x, y: cur.y + y) : P(x: x, y: y)
                start = cur
                path.move(to: transform(cur.x, cur.y))
                any = true
                // implicit subsequent pairs are treated as L, per SVG spec
                cmd = rel ? "l" : "L"
            case "L":
                guard let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                cur = rel ? P(x: cur.x + x, y: cur.y + y) : P(x: x, y: y)
                path.addLine(to: transform(cur.x, cur.y))
            case "H":
                guard let x = nextNumber() else { return any ? path : nil }
                cur = P(x: rel ? cur.x + x : x, y: cur.y)
                path.addLine(to: transform(cur.x, cur.y))
            case "V":
                guard let y = nextNumber() else { return any ? path : nil }
                cur = P(x: cur.x, y: rel ? cur.y + y : y)
                path.addLine(to: transform(cur.x, cur.y))
            case "C":
                guard let x1 = nextNumber(), let y1 = nextNumber(),
                      let x2 = nextNumber(), let y2 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                let c1 = rel ? P(x: cur.x + x1, y: cur.y + y1) : P(x: x1, y: y1)
                let c2 = rel ? P(x: cur.x + x2, y: cur.y + y2) : P(x: x2, y: y2)
                let end = rel ? P(x: cur.x + x, y: cur.y + y) : P(x: x, y: y)
                path.addCurve(to: transform(end.x, end.y),
                              control1: transform(c1.x, c1.y),
                              control2: transform(c2.x, c2.y))
                cur = end
            case "Q":
                guard let x1 = nextNumber(), let y1 = nextNumber(),
                      let x = nextNumber(), let y = nextNumber() else { return any ? path : nil }
                let c = rel ? P(x: cur.x + x1, y: cur.y + y1) : P(x: x1, y: y1)
                let end = rel ? P(x: cur.x + x, y: cur.y + y) : P(x: x, y: y)
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
