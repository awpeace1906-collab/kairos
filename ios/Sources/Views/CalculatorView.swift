import SwiftUI

struct CalculatorView: View {
    let calc: Calculator
    let route: String
    @EnvironmentObject private var session: SessionStore

    @State private var choices: [String: Int] = [:]      // item.key -> option index
    @State private var inputs: [String: String] = [:]    // input.key -> raw string

    private var result: CalcResult {
        CalculatorEngine.run(calc, itemChoices: choices, inputs: inputs)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            switch calc.engine {
            case .additive:                 additiveItems
            case .formula, .external:       formulaInputs
            case .classification:           classificationTiers
            }

            ClearFieldsButton {
                choices = [:]; inputs = [:]
                session.clearScreen(route)
            }

            resultView
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("calc-result")

            if let notes = calc.notes {
                Text(notes).font(.footnote).foregroundStyle(.secondary)
            }
            BuildNote(text: calc.buildNote)
            SourcesBlock(meta: calc.meta)
        }
        .task {
            // restore session state
            let saved = session.fields(route)
            for i in calc.inputs ?? [] where saved[i.key] != nil { inputs[i.key] = saved[i.key] }
            for it in calc.items ?? [] { if let v = saved["item.\(it.key)"], let n = Int(v) { choices[it.key] = n } }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let s = calc.settings, !s.isEmpty {
                Text(s.joined(separator: " · ")).font(.caption).foregroundStyle(.secondary)
            }
            Text(calc.purpose).foregroundStyle(.secondary)
            if let flags = calc.meta.flags, !flags.isEmpty {
                HStack { ForEach(flags, id: \.self) { flag in
                    Text(flag).font(.caption2).padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2), in: Capsule())
                }}
            }
        }
    }

    private var additiveItems: some View {
        ForEach(calc.items ?? []) { item in
            VStack(alignment: .leading, spacing: 6) {
                Text(item.label).font(.subheadline.bold())
                if let help = item.help { Text(help).font(.caption).foregroundStyle(.secondary) }
                ForEach(Array(item.options.enumerated()), id: \.offset) { idx, opt in
                    Button {
                        choices[item.key] = idx
                        session.set(route, "item.\(item.key)", String(idx))
                    } label: {
                        HStack {
                            Text(opt.label)
                            Spacer()
                            Text(opt.points > 0 ? "+\(fmt(opt.points))" : fmt(opt.points))
                                .foregroundStyle(.secondary)
                        }
                        .padding(10)
                        .background(choices[item.key] == idx ? Color.accentColor.opacity(0.2) : Color(.secondarySystemBackground),
                                   in: RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("opt-\(item.key)-\(idx)")
                }
            }
        }
    }

    private var formulaInputs: some View {
        ForEach(calc.inputs ?? []) { input in
            if input.type == "select", let options = input.options {
                VStack(alignment: .leading, spacing: 4) {
                    Text(input.label).font(.subheadline)
                    Picker(input.label, selection: Binding(
                        get: { inputs[input.key] ?? "" },
                        set: { inputs[input.key] = $0; session.set(route, input.key, $0) }
                    )) {
                        Text("—").tag("")
                        ForEach(options) { opt in
                            Text(opt.label).tag(opt.valueString)
                        }
                    }
                    .pickerStyle(.segmented)
                }
            } else {
                ClearableField(
                    label: input.label,
                    unit: input.unit,
                    text: Binding(
                        get: { inputs[input.key] ?? "" },
                        set: { inputs[input.key] = $0; session.set(route, input.key, $0) }
                    )
                )
            }
        }
    }

    private var classificationTiers: some View {
        ForEach(Array((calc.tiers ?? []).enumerated()), id: \.offset) { _, tier in
            VStack(alignment: .leading, spacing: 2) {
                Text(tier.label).bold()
                Text(tier.description).font(.callout)
                if let m = tier.mortality { Text("Mortality: \(m)").font(.caption).foregroundStyle(.secondary) }
            }
            .padding(.vertical, 4)
        }
    }

    @ViewBuilder private var resultView: some View {
        switch calc.engine {
        case .additive:
            if result.incomplete {
                Text("Answer all \(result.totalItems) items — \(result.answered) done")
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Score \(fmt(result.score))").font(.title3)
                    ForEach(Array(result.bands.enumerated()), id: \.offset) { _, band in
                        bandCard(band)
                    }
                }
            }
        case .formula:
            if result.formulaValues.isEmpty {
                Text("Enter values to compute").foregroundStyle(.secondary)
            } else {
                ForEach(result.formulaValues) { v in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(v.label).foregroundStyle(.secondary)
                            Spacer()
                            Text("\(fmt(v.value))\(v.unit.map { " \($0)" } ?? "")").bold()
                        }
                        ForEach(Array((result.bandsByKey[v.key] ?? []).enumerated()), id: \.offset) { _, b in
                            bandCard(b)
                        }
                    }
                    Divider()
                }
            }
        case .external:
            bandCardText("This score has no open formula — structure and cutoff shown above. See build note.", severity: "moderate")
        case .classification:
            Text("Pick the class that matches the exam.").foregroundStyle(.secondary)
        }
    }

    private func bandCard(_ b: Calculator.Band) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(b.label).bold()
            if let r = b.risk { Text(r).font(.callout) }
            if let d = b.disposition { Text(d).font(.callout).foregroundStyle(.secondary) }
            if let d = b.detail { Text(d).font(.callout).foregroundStyle(.secondary) }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.severityColor(b.severity).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
        .overlay(alignment: .leading) { Rectangle().fill(Theme.severityColor(b.severity)).frame(width: 4) }
    }

    private func bandCardText(_ text: String, severity: String) -> some View {
        Text(text)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.severityColor(severity).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
    }

    private func fmt(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(format: "%g", d)
    }
}
