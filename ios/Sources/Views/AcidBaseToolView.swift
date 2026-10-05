import SwiftUI

/// Acid-Base Analyzer — the code-backed calculator (engine: builtin,
/// tool: acid-base). Math lives in Calc/AcidBaseEngine.swift (golden-vector
/// tested); every string comes from AcidBaseContent. Mirrors
/// web/src/views/acidBaseTool.js.
struct AcidBaseToolView: View {
    let calc: Calculator
    let content: AcidBaseContent
    let route: String
    @EnvironmentObject private var session: SessionStore

    @State private var values: [String: String] = [:]
    @State private var chronicity = "unknown"
    @State private var sample = "arterial"
    @FocusState private var focus: String?

    private static let keys = ["ph", "paco2", "hco3", "na", "cl", "albumin"]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            RichText(calc.purpose).foregroundStyle(.secondary)
            inputs
            output
            DisclosureGroup("Why this matters") {
                RichText(content.whyThisMatters).font(Theme.callout).padding(.top, 4)
            }
            .font(Theme.callout)
            takeaway
            SourcesBlock(meta: calc.meta)
        }
        .onAppear(perform: restore)
        // Decimal pad has no Done key; same yellow checkmark as ClearableField.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { focus = nil } label: { Image(systemName: "checkmark.circle.fill").foregroundStyle(.yellow) }
                    .accessibilityLabel("Done")
                    .accessibilityIdentifier("abg-kb-done")
            }
        }
    }

    // MARK: - Inputs

    private func def(_ k: String) -> AcidBaseContent.Field {
        switch k {
        case "ph": return content.fields.ph; case "paco2": return content.fields.paco2; case "hco3": return content.fields.hco3
        case "na": return content.fields.na; case "cl": return content.fields.cl; default: return content.fields.albumin
        }
    }

    private func field(_ k: String) -> some View {
        let d = def(k)
        let label = k == "paco2" && sample == "venous" ? content.sample.venousPco2Label : d.label
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 3) {
                Text(label).font(Theme.caption).foregroundStyle(.secondary)
                if let u = d.unit { Text(u).font(Theme.caption2).foregroundStyle(.tertiary) }
            }
            TextField("", text: Binding(get: { values[k] ?? "" }, set: { values[k] = $0; persist() }))
                .keyboardType(.decimalPad)
                .focused($focus, equals: k)
                .font(Theme.mono(16))
                .padding(.horizontal, 8).padding(.vertical, 8)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel(label)
                .accessibilityIdentifier("abg-\(k)")
        }
    }

    private var inputs: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 8, alignment: .top), count: 3)
        return VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(content.sample.label).font(Theme.caption).foregroundStyle(.secondary)
                Picker(content.sample.label, selection: Binding(get: { sample }, set: { sample = $0; persist() })) {
                    Text(content.sample.options.arterial).tag("arterial")
                    Text(content.sample.options.venous).tag("venous")
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("abg-sample")
                if sample == "venous" { Text(content.sample.help).font(Theme.caption).foregroundStyle(.secondary) }
            }
            LazyVGrid(columns: cols, alignment: .leading, spacing: 10) {
                ForEach(Self.keys, id: \.self) { field($0) }
            }
            Text("Na⁺, Cl⁻ and albumin are optional — they add the anion gap and delta ratio.")
                .font(Theme.caption).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 4) {
                Text(content.chronicity.label).font(Theme.caption).foregroundStyle(.secondary)
                Picker(content.chronicity.label, selection: Binding(get: { chronicity }, set: { chronicity = $0; persist() })) {
                    Text(content.chronicity.options.unknown).tag("unknown")
                    Text(content.chronicity.options.acute).tag("acute")
                    Text(content.chronicity.options.chronic).tag("chronic")
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("abg-chronicity")
                Text(content.chronicity.help).font(Theme.caption).foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Compute

    private func num(_ k: String) -> Double? {
        let t = (values[k] ?? "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        return t.isEmpty ? nil : Double(t)
    }

    private var result: AcidBaseEngine.Result {
        AcidBaseEngine.interpret(.init(ph: num("ph"), paco2: num("paco2"), hco3: num("hco3"),
                                       na: num("na"), cl: num("cl"), albumin: num("albumin"),
                                       chronicity: AcidBaseEngine.Chronicity(rawValue: chronicity) ?? .unknown,
                                       sample: AcidBaseEngine.Sample(rawValue: sample) ?? .arterial))
    }

    // MARK: - Output

    @ViewBuilder private var output: some View {
        let r = result
        VStack(alignment: .leading, spacing: 8) {
            switch r.status {
            case "incomplete": band(content.statusMessages.incomplete, severity: nil)
            case "error": band(content.statusMessages.errors[r.error ?? ""] ?? (r.error ?? ""), severity: "moderate")
            default: details(r)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("abg-result")
    }

    @ViewBuilder private func details(_ r: AcidBaseEngine.Result) -> some View {
        let p = content.primary[r.primary ?? ""]
        let sev = r.phStatus != "normal" ? "high" : (r.disorders.isEmpty ? "low" : "moderate")
        VStack(alignment: .leading, spacing: 3) {
            Text("pH \(values["ph"] ?? "")\(r.sample == "venous" ? " (venous)" : "")").font(Theme.mono(11)).tracking(0.6).foregroundStyle(.secondary)
            Text(p?.label ?? (r.primary ?? "")).font(Theme.semibold(20, relativeTo: .title3))
            Text(content.phText(r.phStatus)).font(Theme.callout)
            if let d = p?.detail { Text(d).font(Theme.caption).foregroundStyle(.secondary) }
        }
        .modifier(BandStyle(severity: sev))

        if let e = r.estimatedArterial {
            line(content.sample.estimatedLabel.uppercased(),
                 "pH \(Self.plain(e.ph)) · PaCO₂ \(Self.plain(e.paco2)) · HCO₃⁻ \(Self.plain(e.hco3))", nil, nil, nil)
        }

        if r.disorders.count > 1 {
            line("DISORDERS PRESENT", r.disorders.map { content.primary[$0]?.label ?? $0 }.joined(separator: " + "), nil, nil, "high")
        }

        if let c = r.compensation {
            let target = c.measured == "paco2" ? "PaCO₂" : "HCO₃⁻"
            let range: (AcidBaseEngine.Band) -> String = { "\(Self.plain($0.lo))–\(Self.plain($0.hi))" }
            let exp = c.expected.map(range) ?? "acute \(c.acute.map(range) ?? "—"), chronic \(c.chronic.map(range) ?? "—")"
            let good = c.key == "appropriate" || c.key.hasPrefix("fits") || c.key == "acute_or_chronic"
            line((content.compensationRules[c.rule]?.label ?? c.rule).uppercased(),
                 "Expected \(target) \(exp) · \(r.sample == "venous" ? "estimated" : "measured") \(Self.plain(AcidBaseEngine.round(c.actual)))",
                 content.compensation[c.key] ?? c.key, content.compensationRules[c.rule]?.formula, good ? "low" : "moderate")
        }

        if let ag = r.ag {
            let corrected = ag.corrected.map { $0 != ag.value } ?? false
            line(content.anionGap.label.uppercased(),
                 corrected ? "\(Self.plain(ag.used)) (measured \(Self.plain(ag.value)))" : Self.plain(ag.value),
                 ag.key == "high" ? content.anionGap.high : content.anionGap.normal,
                 corrected ? content.anionGap.correctedNote : nil, ag.key == "high" ? "high" : "low")
        }

        if let dr = r.deltaRatio {
            line(content.deltaRatio.label.uppercased(), Self.plain(dr.value),
                 content.deltaRatio.bands[dr.key] ?? dr.key, content.deltaRatio.caution, dr.key == "hagma" ? "low" : "moderate")
        }

        ForEach(sortedFlags(r.flags), id: \.self) { f in
            if let d = content.flags[f] { band(d.text, severity: d.level == "warning" ? "high" : nil) }
        }

        ForEach(r.differentials, id: \.self) { k in
            if let d = content.differentials[k] {
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(d.items, id: \.self) { i in
                            HStack(alignment: .firstTextBaseline, spacing: 5) { Text("•"); Text(i) }.font(Theme.callout)
                        }
                        if let n = d.note { Text(n).font(Theme.caption).foregroundStyle(.secondary).padding(.top, 2) }
                    }
                    .padding(.top, 4)
                } label: { Text(d.title).font(Theme.callout) }
                .padding(10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
            }
        }
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

    /// Stacked label → value → text: these lines carry sentences, not short values.
    private func line(_ label: String, _ value: String, _ text: String?, _ detail: String?, _ severity: String?) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(Theme.mono(11)).tracking(0.5).foregroundStyle(.secondary)
            Text(value).bold().monospacedDigit()
            if let t = text { Text(t).font(Theme.callout) }
            if let d = detail { Text(d).font(Theme.caption).foregroundStyle(.secondary) }
        }
        .modifier(BandStyle(severity: severity))
    }

    private func band(_ text: String, severity: String?) -> some View {
        Text(text).font(Theme.callout).modifier(BandStyle(severity: severity))
    }

    private func sortedFlags(_ flags: [String]) -> [String] {
        flags.filter { content.flags[$0]?.level == "warning" } + flags.filter { content.flags[$0]?.level != "warning" }
    }

    static func plain(_ v: Double) -> String { v == v.rounded() ? String(Int(v)) : String(v) }

    // MARK: - State

    private func persist() {
        for k in Self.keys { session.set(route, "abg.\(k)", values[k] ?? "") }
        session.set(route, "abg.chronicity", chronicity)
        session.set(route, "abg.sample", sample)
    }

    private func restore() {
        let s = session.fields(route)
        for k in Self.keys { values[k] = s["abg.\(k)"] ?? "" }
        chronicity = s["abg.chronicity"].flatMap { $0.isEmpty ? nil : $0 } ?? "unknown"
        sample = s["abg.sample"] == "venous" ? "venous" : "arterial"
    }
}
