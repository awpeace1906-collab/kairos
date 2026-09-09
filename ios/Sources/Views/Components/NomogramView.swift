import SwiftUI

/// Renders a `Calculator.Plot` — a linear-x / log10-y plot (e.g. the
/// Rumack-Matthew acetaminophen nomogram). Curve expressions are evaluated with
/// the free variable `x`; the marker is read from the inputs named by
/// plot.x.key / plot.y.key. Mirrors the web `nomogram()` renderer.
struct NomogramView: View {
    let plot: Calculator.Plot
    let inputs: [String: String]

    private let vw: CGFloat = 480, vh: CGFloat = 320
    private let inset = EdgeInsets(top: 14, leading: 54, bottom: 42, trailing: 16)

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Canvas { ctx, size in draw(&ctx, size: size) }
                .aspectRatio(vw / vh, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            Text(caption)
                .font(Theme.mono(11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: geometry

    private func draw(_ ctx: inout GraphicsContext, size: CGSize) {
        let sx = size.width / vw, sy = size.height / vh
        let L = inset.leading * sx, R = size.width - inset.trailing * sx
        let T = inset.top * sy, B = size.height - inset.bottom * sy
        let pw = R - L, ph = B - T
        guard pw > 0, ph > 0, plot.y.min > 0, plot.y.max > plot.y.min, plot.x.max > plot.x.min else { return }

        let lgMin = log10(plot.y.min), lgMax = log10(plot.y.max)
        func lx(_ v: Double) -> CGFloat { L + pw * CGFloat((v - plot.x.min) / (plot.x.max - plot.x.min)) }
        func ly(_ v: Double) -> CGFloat {
            let vv = max(v, plot.y.min)
            return T + ph * CGFloat(1 - (log10(vv) - lgMin) / (lgMax - lgMin))
        }

        let grid = Color(.separator)
        let axisText = Color.secondary
        let danger = Theme.severityColor("high")

        // frame
        ctx.stroke(Path(CGRect(x: L, y: T, width: pw, height: ph)), with: .color(grid), lineWidth: 1)

        // y grid + labels (1-2-5 per decade)
        for v in logTicks(plot.y.min, plot.y.max) {
            let y = ly(v)
            var line = Path(); line.move(to: CGPoint(x: L, y: y)); line.addLine(to: CGPoint(x: R, y: y))
            ctx.stroke(line, with: .color(grid), lineWidth: 1)
            ctx.draw(Text(trimNum(v)).font(Theme.mono(9)).foregroundColor(axisText),
                     at: CGPoint(x: L - 6, y: y), anchor: .trailing)
        }

        // x grid + labels (6 ticks)
        for i in 0...5 {
            let v = plot.x.min + Double(i) / 5 * (plot.x.max - plot.x.min)
            let x = lx(v)
            var line = Path(); line.move(to: CGPoint(x: x, y: T)); line.addLine(to: CGPoint(x: x, y: B))
            ctx.stroke(line, with: .color(grid), lineWidth: 1)
            ctx.draw(Text(trimNum(v)).font(Theme.mono(9)).foregroundColor(axisText),
                     at: CGPoint(x: x, y: B + 12 * sy), anchor: .center)
        }

        // axis titles
        ctx.draw(Text(axisLabel(plot.x)).font(Theme.mono(9)).foregroundColor(axisText),
                 at: CGPoint(x: L + pw / 2, y: size.height - 8 * sy), anchor: .center)
        ctx.drawLayer { layer in
            layer.translateBy(x: 12 * sx, y: T + ph / 2)
            layer.rotate(by: .degrees(-90))
            layer.draw(Text(axisLabel(plot.y)).font(Theme.mono(9)).foregroundColor(axisText), at: .zero, anchor: .center)
        }

        // curves
        for curve in plot.curves {
            let stroke = tone(curve.tone) ?? danger
            var path = Path()
            var started = false
            for i in 0...100 {
                let xv = plot.x.min + Double(i) / 100 * (plot.x.max - plot.x.min)
                guard let yv = try? Expression.evaluate(curve.expression, scope: ["x": xv]),
                      yv.isFinite, yv >= plot.y.min, yv <= plot.y.max else { started = false; continue }
                let p = CGPoint(x: lx(xv), y: ly(yv))
                if started { path.addLine(to: p) } else { path.move(to: p); started = true }
            }
            ctx.stroke(path, with: .color(stroke), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
            if let yEnd = try? Expression.evaluate(curve.expression, scope: ["x": plot.x.max]),
               yEnd.isFinite, yEnd >= plot.y.min, yEnd <= plot.y.max {
                ctx.draw(Text(curve.label).font(Theme.mono(9)).foregroundColor(stroke),
                         at: CGPoint(x: R - 4, y: ly(yEnd) - 7), anchor: .trailing)
            }
        }

        // marker
        if let px = Double(inputs[plot.x.key] ?? ""), let py = Double(inputs[plot.y.key] ?? ""),
           px >= plot.x.min, px <= plot.x.max, py > 0 {
            let cx = lx(px), cy = ly(min(py, plot.y.max))
            let above = (try? Expression.evaluate(plot.curves[0].expression, scope: ["x": px])).map { py >= $0 } ?? false
            let col = above ? Theme.severityColor("high") : Theme.severityColor("low")
            var cross = Path()
            cross.move(to: CGPoint(x: L, y: cy)); cross.addLine(to: CGPoint(x: cx, y: cy))
            cross.move(to: CGPoint(x: cx, y: B)); cross.addLine(to: CGPoint(x: cx, y: cy))
            ctx.stroke(cross, with: .color(col), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            let r: CGFloat = 4.5
            ctx.fill(Path(ellipseIn: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)), with: .color(col))
        }
    }

    // MARK: helpers

    private var caption: String {
        var sub = "Enter a level and a time to plot the point."
        if let px = Double(inputs[plot.x.key] ?? ""), let py = Double(inputs[plot.y.key] ?? ""),
           px >= plot.x.min, px <= plot.x.max, py > 0 {
            let above = (try? Expression.evaluate(plot.curves[0].expression, scope: ["x": px])).map { py >= $0 } ?? false
            let name = plot.curves[0].label.lowercased()
            sub = above ? "Point is on or above the \(name) — treatment indicated." : "Point is below the \(name)."
        }
        return plot.caption.map { "\($0) — \(sub)" } ?? sub
    }

    private func axisLabel(_ a: Calculator.Plot.Axis) -> String {
        a.unit.map { "\(a.label) (\($0))" } ?? a.label
    }

    private func tone(_ t: String?) -> Color? {
        switch t {
        case "accent": return Theme.accent
        case "muted":  return .secondary
        case "danger": return Theme.severityColor("high")
        default:       return nil
        }
    }

    private func logTicks(_ lo: Double, _ hi: Double) -> [Double] {
        var out: [Double] = []
        let d0 = Int(floor(log10(lo))), d1 = Int(ceil(log10(hi)))
        for d in d0...d1 {
            for m in [1.0, 2.0, 5.0] {
                let v = m * pow(10, Double(d))
                if v >= lo - 1e-9 && v <= hi + 1e-9 { out.append(v) }
            }
        }
        return out
    }

    private func trimNum(_ n: Double) -> String {
        let r = abs(n) >= 100 ? (n / 1).rounded() : (n * 10).rounded() / 10
        return r == r.rounded() ? String(Int(r)) : String(format: "%g", r)
    }
}
