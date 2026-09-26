import SwiftUI

/// EKG Axis Interpreter — the code-backed calculator (engine: builtin,
/// tool: ekg-axis). Math lives in Calc/AxisEngine.swift (golden-vector tested);
/// every string comes from AxisToolContent. Mirrors web/src/views/axisTool.js.
struct AxisToolView: View {
    let calc: Calculator
    let content: AxisToolContent
    let route: String
    @EnvironmentObject private var session: SessionStore

    // Machine (P-R-T) is where the screen opens, every time; fields are remembered.
    @State private var mode: String = ""
    @State private var prtText = ""
    @State private var p = ""
    @State private var qrs = ""
    @State private var t = ""
    @State private var pol: [String: [String: AxisEngine.Polarity]] = [:]
    @State private var amps: [String: String] = [:]
    @State private var peds = false
    @State private var ageVal = ""
    @State private var ageUnit = "y"
    @State private var mods: Set<String> = []
    /// Which entry field has the keyboard: "p", "qrs", "t", "amp.<lead>",
    /// "age", or "paste". Drives the keyboard bar's ± and Done keys.
    @FocusState private var focus: String?

    private static let leadAngles: [(String, Double)] = [("I", 0), ("II", 60), ("III", 120), ("aVR", -150), ("aVL", -30), ("aVF", 90)]

    private var modeDef: AxisToolContent.Mode {
        content.modes.first { $0.id == mode } ?? content.modes.first { $0.default == true } ?? content.modes[0]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RichText(calc.purpose).foregroundStyle(.secondary)
            modePicker
            Text(modeDef.help).font(Theme.callout).foregroundStyle(.secondary)
            modePanel
            Divider()
            sharedControls
            output
            DisclosureGroup("Why this matters") {
                RichText(content.whyThisMatters).font(Theme.callout).padding(.top, 4)
            }
            .font(Theme.callout)
            takeaway
            SourcesBlock(meta: calc.meta)
        }
        .onAppear(perform: restore)
        // The decimal pad has no minus key and no Done key. One bar for the
        // whole screen (per-field toolbars stack up duplicates): ± flips the
        // focused signed field, the yellow checkmark collapses the keyboard,
        // matching ClearableField elsewhere in the app.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                if let key = focus, let b = signedBinding(key) {
                    Button { b.wrappedValue = Self.flipSign(b.wrappedValue) } label: {
                        Text("±").font(.system(size: 22, weight: .semibold)).frame(minWidth: 44)
                    }
                    .accessibilityLabel("Toggle sign")
                    .accessibilityIdentifier("axis-kb-sign")
                }
                Spacer()
                Button { focus = nil } label: {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(.yellow)
                }
                .accessibilityLabel("Done")
                .accessibilityIdentifier("axis-kb-done")
            }
        }
    }

    /// Binding for a signed entry field by focus key; nil for unsigned fields.
    private func signedBinding(_ key: String) -> Binding<String>? {
        switch key {
        case "p":   return Binding(get: { p }, set: { p = $0; persist() })
        case "qrs": return Binding(get: { qrs }, set: { qrs = $0; persist() })
        case "t":   return Binding(get: { t }, set: { t = $0; persist() })
        default:
            guard key.hasPrefix("amp.") else { return nil }
            let lead = String(key.dropFirst(4))
            return Binding(get: { amps[lead] ?? "" }, set: { amps[lead] = $0; persist() })
        }
    }

    static func flipSign(_ s: String) -> String {
        let t = s.replacingOccurrences(of: "\u{2212}", with: "-")
        return t.hasPrefix("-") ? String(t.dropFirst()) : "-" + t
    }

    // MARK: - Inputs

    private var modePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(content.modes) { m in
                    Button { mode = m.id } label: {
                        Text(m.label).font(Theme.callout)
                            .padding(.horizontal, 12).padding(.vertical, 7)
                            .foregroundStyle(modeDef.id == m.id ? Color.white : Color.primary)
                            .background(modeDef.id == m.id ? Theme.accent : Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(modeDef.id == m.id ? .isSelected : [])
                    .accessibilityIdentifier("axis-mode-\(m.id)")
                }
            }
        }
    }

    @ViewBuilder private var modePanel: some View {
        switch modeDef.engineMode ?? "prt" {
        case "polarity":
            VStack(alignment: .leading, spacing: 8) {
                ForEach(modeDef.leads ?? [], id: \.self) { lead in
                    HStack(spacing: 10) {
                        Text(lead).font(Theme.mono(14)).fontWeight(.semibold).frame(width: 38, alignment: .leading)
                        ForEach([(AxisEngine.Polarity.pos, "+"), (.iso, "equiphasic"), (.neg, "−")], id: \.0) { v, text in
                            let on = pol[modeDef.id]?[lead] == v
                            Button {
                                var s = pol[modeDef.id] ?? [:]
                                s[lead] = on ? nil : v
                                pol[modeDef.id] = s
                                persist()
                            } label: {
                                Text(text).font(Theme.callout).frame(minWidth: 36)
                                    .padding(.horizontal, 10).padding(.vertical, 7)
                                    .foregroundStyle(on ? Color.white : Color.primary)
                                    .background(on ? Theme.accent : Color(.secondarySystemBackground), in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Lead \(lead) \(text)")
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }
            }
        case "amplitudes":
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(modeDef.leads ?? [], id: \.self) { lead in
                    SignedField(label: lead, unit: "mm", key: "amp.\(lead)", focus: $focus,
                                text: signedBinding("amp.\(lead)")!)
                }
            }
        default:
            VStack(alignment: .leading, spacing: 10) {
                TextField("P-R-T axes 54 −42 38", text: Binding(get: { prtText }, set: { onPaste($0) }))
                    .font(Theme.mono(15))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    .focused($focus, equals: "paste")
                    .accessibilityIdentifier("axis-paste")
                HStack(spacing: 8) {
                    SignedField(label: "P", unit: "°", key: "p", focus: $focus, text: signedBinding("p")!)
                    SignedField(label: "QRS", unit: "°", key: "qrs", focus: $focus, text: signedBinding("qrs")!)
                    SignedField(label: "T", unit: "°", key: "t", focus: $focus, text: signedBinding("t")!)
                }
            }
        }
    }

    private var sharedControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Picker("Age group", selection: Binding(get: { peds }, set: { peds = $0; persist() })) {
                    Text("Adult").tag(false)
                    Text("Peds").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(maxWidth: 170)
                if peds {
                    TextField("age", text: Binding(get: { ageVal }, set: { ageVal = $0; persist() }))
                        .keyboardType(.decimalPad)
                        .focused($focus, equals: "age")
                        .frame(width: 54)
                        .padding(6)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    Picker("Unit", selection: Binding(get: { ageUnit }, set: { ageUnit = $0; persist() })) {
                        Text("days").tag("d"); Text("months").tag("m"); Text("years").tag("y")
                    }
                    .pickerStyle(.menu)
                }
            }
            FlowLayout(spacing: 6) {
                ForEach(content.modifiers) { m in
                    let on = mods.contains(m.id)
                    Button {
                        if on { mods.remove(m.id) } else { mods.insert(m.id) }
                        persist()
                    } label: {
                        Text(m.label).font(Theme.caption)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .foregroundStyle(on ? Color.white : Color.primary)
                            .background(on ? Theme.accent : Color(.secondarySystemBackground), in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                }
            }
        }
    }

    // MARK: - Compute

    private func num(_ s: String) -> Double? {
        let t = s.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "\u{2212}", with: "-")
            .replacingOccurrences(of: "\u{2013}", with: "-")
            .replacingOccurrences(of: ",", with: ".")   // comma-decimal locales' keypad
        return t.isEmpty || t == "-" ? nil : Double(t)
    }

    private var ageDays: Double? {
        guard peds, let v = num(ageVal), v >= 0 else { return nil }
        switch ageUnit { case "d": return v; case "m": return v * 30.4375; default: return v * 365 }
    }

    private var modifiers: AxisEngine.Modifiers {
        .init(lbbb: mods.contains("lbbb"), rbbb: mods.contains("rbbb"), paced: mods.contains("paced"),
              lvh: mods.contains("lvh"), wpw: mods.contains("wpw"), wideQrs: mods.contains("wideQrs"))
    }

    /// (result, message-only status, parse warnings)
    private var computed: (AxisEngine.AxisResult?, String?, [String]) {
        switch modeDef.engineMode ?? "prt" {
        case "polarity":
            var sel: [String: AxisEngine.Polarity] = [:]
            for l in modeDef.leads ?? [] { if let v = pol[modeDef.id]?[l] { sel[l] = v } }
            let r = AxisEngine.interpret(.polarities(sel), ageDays: ageDays, modifiers: modifiers)
            return r.status == "ok" ? (r, nil, []) : (nil, r.status, r.warnings)
        case "amplitudes":
            var a: [String: Double] = [:]
            for l in modeDef.leads ?? [] { if let v = num(amps[l] ?? "") { a[l] = v } }
            let r = AxisEngine.interpret(.amplitudes(a), ageDays: ageDays, modifiers: modifiers)
            return r.status == "ok" ? (r, nil, []) : (nil, r.status, r.warnings)
        default:
            var parseWarnings: [String] = []
            var parseError: String?
            if !prtText.trimmingCharacters(in: .whitespaces).isEmpty {
                switch AxisEngine.parsePRT(prtText) {
                case .success(let parsed): parseWarnings = parsed.warnings
                case .failure(let e): parseError = e.rawValue
                }
            }
            guard let q = num(qrs) else {
                return (nil, parseError ?? (qrs.trimmingCharacters(in: .whitespaces).isEmpty ? "empty" : "qrs_missing"), [])
            }
            let r = AxisEngine.interpret(.prtValues(p: num(p), qrs: q, t: num(t)), ageDays: ageDays, modifiers: modifiers)
            return (r, nil, parseWarnings)
        }
    }

    // MARK: - Output

    @ViewBuilder private var output: some View {
        let (r, status, warns) = computed
        VStack(alignment: .leading, spacing: 8) {
            if let status {
                band(content.statusMessages.message(status) ?? status,
                     severity: status == "empty" || status == "no_input" || status == "need_two_leads" ? nil : "moderate")
            }
            ForEach(warns, id: \.self) { w in band(content.warnings[w] ?? w, severity: "moderate") }
            if let r { result(r) } else { AxisWheel(result: nil, peds: peds) }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("axis-result")
    }

    @ViewBuilder private func result(_ r: AxisEngine.AxisResult) -> some View {
        let qc = r.qrsClass
        let key = qc?.key ?? ""
        VStack(alignment: .leading, spacing: 2) {
            Text("QRS AXIS").font(Theme.mono(11)).tracking(0.6).foregroundStyle(.secondary)
            Text(headlineValue(r)).font(Theme.display(30)).monospacedDigit()
            Text(content.qrsCategories[key]?.label ?? key).fontWeight(.semibold)
            if let sub = headlineSub(r) { Text(sub).font(Theme.caption).foregroundStyle(.secondary) }
        }
        .modifier(BandStyle(severity: sev(qc?.severity)))

        AxisWheel(result: r, peds: peds)

        if case .prt = modeKind {
            line("P AXIS", r.pAxis.map(Self.deg) ?? "—", content.pCategories[r.pClass?.key ?? ""], r.pClass?.severity)
            if let tc = r.tClass, let ta = r.tAxis {
                line("T AXIS", Self.deg(ta), content.tCategories[tc.key], tc.severity)
                if let qt = r.qrsT {
                    line("QRS-T ANGLE", "\(qt.angle)°", content.qrsTCategories[qt.key],
                         qt.key == "normal" ? "normal" : qt.key == "abnormal" ? "abnormal" : "borderline")
                }
            }
        }

        ForEach(r.warnings, id: \.self) { w in
            if w == "add_lead_II" && modeDef.id == "quadrant" {
                VStack(alignment: .leading, spacing: 6) {
                    Text(content.warnings[w] ?? w)
                    Button("Add lead II ›", action: jumpToThreeLead).font(Theme.callout)
                        .accessibilityIdentifier("axis-add-lead-ii")
                }
                .modifier(BandStyle(severity: "moderate"))
            } else {
                band(content.warnings[w] ?? w, severity: "moderate")
            }
        }

        ForEach(sortedFlags(r.flags), id: \.self) { f in
            if let def = content.flags[f] {
                let severity = def.level == "warning" ? "high" : nil
                if let ref = def.checklist, let cl = content.checklists[ref] {
                    DisclosureGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cl.title).font(Theme.callout).fontWeight(.semibold)
                            ForEach(cl.items, id: \.self) { i in
                                HStack(alignment: .firstTextBaseline, spacing: 5) { Text("•"); Text(i) }.font(Theme.callout)
                            }
                            if let c = cl.caveat { Text(c).font(Theme.caption).foregroundStyle(.secondary) }
                        }
                        .padding(.top, 4)
                    } label: { Text(def.text).font(Theme.callout) }
                    .modifier(BandStyle(severity: severity))
                } else {
                    band(def.text, severity: severity)
                }
            }
        }

        if let d = r.differential, let list = content.differentials[d] {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(list, id: \.self) { i in
                        HStack(alignment: .firstTextBaseline, spacing: 5) { Text("•"); Text(i) }.font(Theme.callout)
                    }
                }
                .padding(.top, 4)
            } label: { Text("Differential — \(content.qrsCategories[key]?.label ?? d)").font(Theme.callout) }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        if peds {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(content.peds.bands, id: \.age) { b in
                        (Text(b.age).bold() + Text("  \(b.range)")).font(Theme.callout)
                    }
                    Text(content.peds.note).font(Theme.caption).foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            } label: { Text("Pediatric normal ranges").font(Theme.callout) }
            .padding(10)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private enum ModeKind { case prt, polarity, amplitudes }
    private var modeKind: ModeKind {
        switch modeDef.engineMode ?? "prt" { case "polarity": return .polarity; case "amplitudes": return .amplitudes; default: return .prt }
    }

    private var takeaway: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("CLINICAL TAKEAWAY").font(Theme.mono(11)).tracking(0.8).foregroundStyle(Theme.accent)
            RichText(content.clinicalTakeaway).font(Theme.callout).fontWeight(.medium)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 3) }
    }

    private func line(_ label: String, _ value: String, _ def: AxisToolContent.Category?, _ severity: String?) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(label).font(Theme.mono(11)).tracking(0.5).foregroundStyle(.secondary)
                Text(value).bold().monospacedDigit()
                if let l = def?.label { Text(l).font(Theme.callout) }
            }
            if let d = def?.detail { Text(d).font(Theme.caption).foregroundStyle(.secondary) }
        }
        .modifier(BandStyle(severity: sev(severity)))
    }

    private func band(_ text: String, severity: String?) -> some View {
        Text(text).font(Theme.callout).modifier(BandStyle(severity: severity))
    }

    private func sortedFlags(_ flags: [String]) -> [String] {
        flags.filter { content.flags[$0]?.level == "warning" } + flags.filter { content.flags[$0]?.level != "warning" }
    }

    private func sev(_ s: String?) -> String? {
        switch s { case "normal": return "low"; case "borderline": return "moderate"; case "abnormal": return "high"; default: return nil }
    }

    static func deg(_ v: Double) -> String {
        let r = Int(v.rounded())
        return r > 0 ? "+\(r)°" : r < 0 ? "−\(abs(r))°" : "0°"
    }

    private func headlineValue(_ r: AxisEngine.AxisResult) -> String {
        if let a = r.qrsAxis { return Self.deg(a) }
        if let rg = r.qrsRange, rg.count == 2 { return "\(Self.deg(Double(rg[0]))) to \(Self.deg(Double(rg[1])))" }
        return ""
    }

    private func headlineSub(_ r: AxisEngine.AxisResult) -> String? {
        guard let qc = r.qrsClass else { return nil }
        if let b = qc.band { return "Normal for age: \(Self.deg(b.lo)) to \(Self.deg(b.hi))" }
        if qc.key == "spans", let keys = qc.keys { return keys.map { content.qrsCategories[$0]?.label ?? $0 }.joined(separator: " / ") }
        return content.qrsCategories[qc.key]?.range
    }

    // MARK: - State

    private func onPaste(_ text: String) {
        prtText = text
        if case .success(let parsed) = AxisEngine.parsePRT(text) {
            p = parsed.p.map { Self.plain($0) } ?? ""
            qrs = parsed.qrs.map { Self.plain($0) } ?? ""
            t = parsed.t.map { Self.plain($0) } ?? ""
        }
        persist()
    }

    private static func plain(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }

    private func jumpToThreeLead() {
        var s = pol["three_lead"] ?? [:]
        if let i = pol["quadrant"]?["I"] { s["I"] = i }
        if let f = pol["quadrant"]?["aVF"] { s["aVF"] = f }
        pol["three_lead"] = s
        mode = "three_lead"
        persist()
    }

    private func persist() {
        let f: [String: String] = [
            "axis.prtText": prtText, "axis.p": p, "axis.qrs": qrs, "axis.t": t,
            "axis.peds": peds ? "1" : "", "axis.ageVal": ageVal, "axis.ageUnit": ageUnit,
            "axis.mods": mods.sorted().joined(separator: ","),
            "axis.pol": pol.flatMap { m, leads in leads.map { "\(m).\($0.key)=\($0.value.rawValue)" } }.sorted().joined(separator: ","),
            "axis.amps": amps.filter { !$0.value.isEmpty }.map { "\($0.key)=\($0.value)" }.sorted().joined(separator: ","),
        ]
        for (k, v) in f { session.set(route, k, v) }
    }

    private func restore() {
        mode = (content.modes.first { $0.default == true } ?? content.modes[0]).id
        let s = session.fields(route)
        prtText = s["axis.prtText"] ?? ""; p = s["axis.p"] ?? ""; qrs = s["axis.qrs"] ?? ""; t = s["axis.t"] ?? ""
        peds = s["axis.peds"] == "1"; ageVal = s["axis.ageVal"] ?? ""; ageUnit = s["axis.ageUnit"].flatMap { $0.isEmpty ? nil : $0 } ?? "y"
        mods = Set((s["axis.mods"] ?? "").split(separator: ",").map(String.init))
        for entry in (s["axis.pol"] ?? "").split(separator: ",") {
            let kv = entry.split(separator: "="), path = kv.first?.split(separator: ".") ?? []
            if kv.count == 2, path.count == 2, let v = AxisEngine.Polarity(rawValue: String(kv[1])) {
                pol[String(path[0]), default: [:]][String(path[1])] = v
            }
        }
        for entry in (s["axis.amps"] ?? "").split(separator: ",") {
            let kv = entry.split(separator: "=")
            if kv.count == 2 { amps[String(kv[0])] = String(kv[1]) }
        }
    }
}

/// A numeric field with a ± button: iPhone decimal and number pads have no
/// minus key, and negative axes are routine.
private struct SignedField: View {
    let label: String
    let unit: String
    let key: String
    var focus: FocusState<String?>.Binding
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(Theme.caption).foregroundStyle(.secondary)
            HStack(spacing: 4) {
                Button { text = AxisToolView.flipSign(text) } label: {
                    Text("±").font(.system(size: 17, weight: .medium)).frame(width: 30, height: 34)
                        .background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Toggle sign of \(label)")
                TextField("", text: $text)
                    .keyboardType(.decimalPad)
                    .focused(focus, equals: key)
                    .font(Theme.mono(15))
                    .padding(.horizontal, 6).padding(.vertical, 7)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                    .accessibilityLabel(label)
                Text(unit).font(Theme.caption).foregroundStyle(.secondary)
            }
        }
    }
}

private struct BandStyle: ViewModifier {
    let severity: String?
    func body(content: Content) -> some View {
        content
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((severity.map { Theme.severityColor($0) } ?? .secondary).opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            .overlay(alignment: .leading) {
                Rectangle().fill(severity.map { Theme.severityColor($0) } ?? Color(.separator)).frame(width: 4)
            }
    }
}

/// Original hexaxial drawing (no LITFL imagery). 0° at lead I (right), +90° at
/// aVF (down): screen y grows downward, so angles map straight onto the canvas.
private struct AxisWheel: View {
    let result: AxisEngine.AxisResult?
    let peds: Bool

    var body: some View {
        VStack(spacing: 4) {
            Canvas { ctx, size in
                let side = min(size.width, size.height)
                let c = CGPoint(x: size.width / 2, y: size.height / 2)
                let R = side * 0.37
                func pt(_ a: Double, _ r: CGFloat) -> CGPoint {
                    let rad = a * .pi / 180
                    return CGPoint(x: c.x + r * CGFloat(cos(rad)), y: c.y + r * CGFloat(sin(rad)))
                }
                func wedge(_ a1: Double, _ a2: Double, _ r: CGFloat) -> Path {
                    var span = a2 - a1
                    while span < 0 { span += 360 }
                    var path = Path()
                    path.move(to: c)
                    var a = a1
                    while a < a1 + span { path.addLine(to: pt(a, r)); a += 2 }
                    path.addLine(to: pt(a1 + span, r))
                    path.closeSubpath()
                    return path
                }
                if peds {
                    ctx.fill(Path(ellipseIn: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R)), with: .color(.secondary.opacity(0.08)))
                    if let b = result?.qrsClass?.band {
                        ctx.fill(wedge(b.lo, b.hi, R), with: .color(Theme.severityColor("low").opacity(0.25)))
                    }
                } else {
                    ctx.fill(wedge(-30, 90, R), with: .color(Theme.severityColor("low").opacity(0.22)))
                    ctx.fill(wedge(-45, -30, R), with: .color(Theme.severityColor("moderate").opacity(0.22)))
                    ctx.fill(wedge(-90, -45, R), with: .color(Theme.severityColor("high").opacity(0.16)))
                    ctx.fill(wedge(90, 180, R), with: .color(Theme.severityColor("high").opacity(0.16)))
                    ctx.fill(wedge(-180, -90, R), with: .color(Theme.severityColor("critical").opacity(0.26)))
                }
                if let rg = result?.qrsRange, rg.count == 2, result?.qrsAxis == nil {
                    let w = wedge(Double(rg[0]), Double(rg[1]), R + 12)
                    ctx.fill(w, with: .color(Theme.accent.opacity(0.22)))
                    ctx.stroke(w, with: .color(Theme.accent), style: StrokeStyle(lineWidth: 1.2, dash: [3, 3]))
                }
                for (lead, a) in [("I", 0.0), ("II", 60), ("III", 120), ("aVR", -150), ("aVL", -30), ("aVF", 90)] {
                    var neg = Path(); neg.move(to: c); neg.addLine(to: pt(a + 180, R))
                    ctx.stroke(neg, with: .color(.secondary.opacity(0.45)), style: StrokeStyle(lineWidth: 1, dash: [2, 3]))
                    var pos = Path(); pos.move(to: c); pos.addLine(to: pt(a, R))
                    ctx.stroke(pos, with: .color(.secondary.opacity(0.7)), lineWidth: 1)
                    ctx.draw(Text(lead).font(Theme.mono(11)).fontWeight(.semibold), at: pt(a, R + 16))
                }
                for a in [-120.0, -60, 30, 150, 180] {
                    ctx.draw(Text(AxisToolView.deg(a).replacingOccurrences(of: "+", with: "")).font(Theme.mono(9)).foregroundColor(.secondary),
                             at: pt(a, R - 12))
                }
                ctx.stroke(Path(ellipseIn: CGRect(x: c.x - R, y: c.y - R, width: 2 * R, height: 2 * R)), with: .color(Color(.separator)), lineWidth: 1.5)
                func needle(_ a: Double, _ len: CGFloat, _ color: Color, _ style: StrokeStyle) {
                    var n = Path(); n.move(to: c); n.addLine(to: pt(a, len))
                    ctx.stroke(n, with: .color(color), style: style)
                }
                if let pa = result?.pAxis { needle(pa, R - 8, Theme.severityColor("low"), StrokeStyle(lineWidth: 1.6, lineCap: .round)) }
                if let ta = result?.tAxis { needle(ta, R - 8, Theme.accent, StrokeStyle(lineWidth: 2, lineCap: .round, dash: [5, 4])) }
                if let qa = result?.qrsAxis ?? result?.qrsEstimate.map(Double.init) {
                    needle(qa, R + 4, .primary, StrokeStyle(lineWidth: 3.5, lineCap: .round, dash: result?.qrsAxis == nil ? [6, 4] : []))
                    let h = pt(qa, R + 4)
                    ctx.fill(Path(ellipseIn: CGRect(x: h.x - 4.5, y: h.y - 4.5, width: 9, height: 9)), with: .color(.primary))
                }
                ctx.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(.primary))
            }
            .frame(height: 250)
            .accessibilityLabel("Hexaxial reference showing the QRS axis")
            HStack(spacing: 10) {
                legend("QRS", .primary, [])
                if result?.pAxis != nil { legend("P", Theme.severityColor("low"), []) }
                if result?.tAxis != nil { legend("T", Theme.accent, [4, 3]) }
            }
            .font(Theme.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity)
    }

    private func legend(_ label: String, _ color: Color, _ dash: [CGFloat]) -> some View {
        HStack(spacing: 4) {
            Path { p in p.move(to: CGPoint(x: 0, y: 4)); p.addLine(to: CGPoint(x: 18, y: 4)) }
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, dash: dash))
                .frame(width: 18, height: 8)
            Text(label)
        }
    }
}

/// Wraps its subviews onto as many rows as needed (modifier chips).
private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > 0 && x + sz.width > width { x = 0; y += rowH + spacing; rowH = 0 }
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x > bounds.minX && x + sz.width > bounds.maxX { x = bounds.minX; y += rowH + spacing; rowH = 0 }
            s.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            rowH = max(rowH, sz.height)
        }
    }
}
