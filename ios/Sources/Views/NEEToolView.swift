import SwiftUI
import NEECore

/// NEE calculator (engine: builtin, tool: nee). Every agent, unit, factor,
/// label, message, note and citation comes from the bundled kit file
/// nee-logic.json at runtime; this view lays it out in Kairos's skin following
/// Resources/NEE/CODE-INSTRUCTIONS.md. Values live in @State only (no
/// SessionStore) and the result updates live. Mirrors web/src/views/neeTool.js.
struct NEEToolView: View {
    @State private var logic: NEELogic?
    @State private var loadFailed = false
    @State private var formulaId = ""
    @State private var weight = ""
    @State private var salt = ""
    @State private var doses: [String: String] = [:]
    @State private var units: [String: String] = [:]
    @FocusState private var focus: String?

    var body: some View {
        Group {
            if let logic {
                tool(logic)
            } else if loadFailed {
                Text("This tool could not load. Reinstall or update Kairos.")
                    .font(Theme.callout).modifier(BandStyle(severity: "moderate"))
            } else {
                ProgressView()
            }
        }
        .onAppear(perform: load)
    }

    private func load() {
        guard logic == nil else { return }
        guard let url = Bundle.main.url(forResource: "nee-logic", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let parsed = try? NEELogic.load(from: data) else { loadFailed = true; return }
        logic = parsed
        reset(parsed)
    }

    private func reset(_ logic: NEELogic) {
        formulaId = logic.defaultFormula?.id ?? ""
        weight = ""
        salt = logic.norepinephrineSalt.defaultId
        doses = [:]
        units = Dictionary(uniqueKeysWithValues: logic.agents.map { ($0.id, $0.defaultUnit ?? "") })
    }

    // MARK: - Input mapping

    /// Blank → nil (row not entered); unparseable → .nan (engine reports it).
    private func parse(_ s: String?) -> Double? {
        let t = (s ?? "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        if t.isEmpty { return nil }
        return Double(t) ?? .nan
    }

    private func input(_ logic: NEELogic) -> NEEInput {
        NEEInput(formulaId: formulaId, weightKg: parse(weight), neSalt: salt,
                 infusions: logic.agents.compactMap { a in
                     parse(doses[a.id]).map { NEEInfusion(agent: a.id, dose: $0, unit: units[a.id] ?? "") }
                 })
    }

    private func weightNeeded(_ logic: NEELogic) -> Bool {
        logic.agents.contains { a in
            parse(doses[a.id]) != nil && (a.inputUnits.first { $0.unit == units[a.id] }?.perWeight ?? false)
        }
    }

    private func fmt(_ v: Double?, _ d: Int) -> String { v.map { String(format: "%.\(d)f", $0) } ?? "" }

    // MARK: - Layout

    @ViewBuilder private func tool(_ logic: NEELogic) -> some View {
        let f = logic.formula(formulaId)
        let r = computeNEE(logic: logic, input: input(logic))
        VStack(alignment: .leading, spacing: 16) {
            // Formula picker + description
            VStack(alignment: .leading, spacing: 6) {
                Text(logic.ui.formulaLabel).font(Theme.caption).foregroundStyle(.secondary)
                Picker(logic.ui.formulaLabel, selection: $formulaId) {
                    ForEach(logic.formulas) { Text($0.label).tag($0.id) }
                }
                .pickerStyle(.menu).tint(Theme.accent)
                .accessibilityIdentifier("nee-formula")
                if let f { Text(f.description).font(Theme.footnote).foregroundStyle(.secondary) }
            }
            // Weight
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(logic.ui.weightLabel).font(Theme.caption).foregroundStyle(.secondary)
                    if weightNeeded(logic) {
                        Text(logic.ui.weightRequiredMarker).font(Theme.mono(11)).foregroundStyle(Theme.severityColor("high"))
                    }
                }
                field("weight", text: $weight, label: logic.ui.weightLabel)
            }
            // Infusions, then adjuncts
            ForEach(logic.agents.filter { !$0.isAdjunct }) { agentRow(logic, $0, formula: f) }
            Text(logic.ui.adjunctsHeading).font(Theme.headline)
            ForEach(logic.agents.filter(\.isAdjunct)) { agentRow(logic, $0, formula: f) }
            Button(logic.ui.clearAll) { reset(logic); focus = nil }
                .buttonStyle(.bordered).tint(.secondary)
                .accessibilityIdentifier("nee-clear")

            result(logic, r, formula: f)
            footer(logic, r)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { focus = nil } label: { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent) }
                    .accessibilityLabel("Done")
            }
        }
    }

    private func field(_ key: String, text: Binding<String>, label: String) -> some View {
        TextField("", text: text)
            .keyboardType(.decimalPad)
            .focused($focus, equals: key)
            .font(Theme.mono(16))
            .padding(.horizontal, 10).padding(.vertical, 8)
            .frame(maxWidth: 160)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            .accessibilityLabel(label)
            .accessibilityIdentifier("nee-field-\(key)")
    }

    @ViewBuilder private func agentRow(_ logic: NEELogic, _ a: NEELogic.Agent, formula: NEELogic.Formula?) -> some View {
        let inFormula = formula?.factors[a.id] != nil
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(a.label).font(Theme.headline)
                Spacer()
                if !inFormula {
                    Text(logic.ui.notInFormulaMarker.uppercased()).font(Theme.mono(10)).tracking(0.6).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                field(a.id, text: Binding(get: { doses[a.id] ?? "" }, set: { doses[a.id] = $0 }), label: a.label)
                if a.inputUnits.count > 1 {
                    Picker(a.label, selection: Binding(get: { units[a.id] ?? "" }, set: { units[a.id] = $0 })) {
                        ForEach(a.inputUnits, id: \.unit) { Text($0.unit).tag($0.unit) }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("nee-unit-\(a.id)")
                } else if let u = a.inputUnits.first {
                    Text(u.unit).font(Theme.mono(13)).foregroundStyle(.secondary)
                }
            }
            if a.id == logic.norepinephrineSalt.appliesToAgent {
                VStack(alignment: .leading, spacing: 4) {
                    Text(logic.ui.saltLabel).font(Theme.caption).foregroundStyle(.secondary)
                    Picker(logic.ui.saltLabel, selection: $salt) {
                        ForEach(logic.norepinephrineSalt.options) { Text($0.label).tag($0.id) }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
        .padding(10)
        .background(Color(.secondarySystemBackground).opacity(inFormula ? 1 : 0.5), in: RoundedRectangle(cornerRadius: 10))
        .opacity(inFormula ? 1 : 0.7)
        .accessibilityElement(children: .contain)
    }

    // MARK: Result + breakdown

    @ViewBuilder private func result(_ logic: NEELogic, _ r: NEEResult, formula: NEELogic.Formula?) -> some View {
        let dec = logic.output.displayDecimals
        VStack(alignment: .leading, spacing: 10) {
            if r.status == "error" {
                ForEach(Array(r.errors.enumerated()), id: \.offset) { _, e in
                    Text(e.text).font(Theme.callout).modifier(BandStyle(severity: "high"))
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(logic.ui.resultLabel).font(Theme.mono(11)).tracking(0.8).foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(fmt(r.neeMcgKgMin, dec.neeMcgKgMin)).font(Theme.display(34, relativeTo: .largeTitle)).monospacedDigit()
                        Text(logic.output.primaryUnit).font(Theme.mono(14))
                    }
                    if let mcgMin = r.neeMcgMin {
                        Text("\(fmt(mcgMin, dec.neeMcgMin)) \(logic.output.secondaryUnit)").font(Theme.mono(14)).foregroundStyle(.secondary)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("nee-result")
                if let adj = r.adjunctMcgKgMin {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(logic.ui.adjunctLine
                            .replacingOccurrences(of: "{value}", with: fmt(adj, dec.adjunctMcgKgMin))
                            .replacingOccurrences(of: "{unit}", with: logic.output.adjunctUnit))
                            .font(Theme.footnote)
                            .accessibilityIdentifier("nee-adjunct")
                        if let note = r.info.first(where: { $0.code == "adjunct_note" }) {
                            Text(note.text).font(Theme.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3])).foregroundStyle(Color(.separator)))
                }
                ForEach(Array(r.warnings.enumerated()), id: \.offset) { _, w in
                    Text(w.text).font(Theme.callout).modifier(BandStyle(severity: "moderate"))
                }
                ForEach(Array(r.info.filter { $0.code != "adjunct_note" }.enumerated()), id: \.offset) { _, i in
                    Text(i.text).font(Theme.callout).modifier(BandStyle(severity: nil))
                }
                if !r.breakdown.isEmpty {
                    Text(logic.ui.breakdownHeading).font(Theme.headline)
                    ForEach(Array(r.breakdown.enumerated()), id: \.offset) { _, b in
                        breakdownLine(logic, b, formula: formula)
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) { Rectangle().fill(Theme.accent).frame(width: 3) }
    }

    private func breakdownLine(_ logic: NEELogic, _ b: NEEBreakdownRow, formula: NEELogic.Formula?) -> some View {
        let dec = logic.output.displayDecimals
        let label = logic.agent(b.agent)?.label ?? b.agent
        let dose = "\(fmt(b.doseCanonical, dec.doseCanonical)) \(b.canonicalUnit)"
        let tail: String
        if let pub = formula?.factors[b.agent]?.publishedAs {
            let unit = b.adjunct ? logic.output.adjunctUnit : logic.output.primaryUnit
            tail = " → \(pub) → \(fmt(b.contribution, dec.contributionMcgKgMin)) \(unit)"
        } else {
            tail = " → \(logic.ui.notInFormulaMarker)"
        }
        return (Text(label).bold() + Text(" \(dose)\(tail)"))
            .font(Theme.footnote).monospacedDigit()
            .foregroundStyle(b.counted ? Color.primary : Color.secondary)
    }

    // MARK: Footer: static notes, then sources per ui.sources_rule

    @ViewBuilder private func footer(_ logic: NEELogic, _ r: NEEResult) -> some View {
        let statics = logic.contextNotes.filter { $0.type == "static" }
        let shownInfo = r.status == "ok" ? r.info.map(\.code).filter { logic.note($0) != nil } : []
        let ids = neeSourceIds(logic: logic, formulaId: formulaId, shownNoteIds: shownInfo + statics.map(\.id))
        VStack(alignment: .leading, spacing: 8) {
            ForEach(statics) { Text($0.text).font(Theme.footnote).foregroundStyle(.secondary) }
            Text(logic.ui.sourcesHeading.uppercased()).font(Theme.mono(11)).tracking(0.8).foregroundStyle(.secondary).padding(.top, 4)
            ForEach(Array(ids.enumerated()), id: \.offset) { i, k in
                Text("\(i + 1). \(logic.citations[k] ?? k)").font(Theme.caption)
            }
        }
    }
}
