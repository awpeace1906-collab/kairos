import SwiftUI

// Dual-mode weight/zone (Dual_Mode_Weight_Zone_Spec.md):
//  - zone bar = equipment sizes + visual anchor ONLY
//  - every dose below is computed live from the exact weight entered (or the
//    age-estimate, flagged "estimated") — never read from the zone.

struct DrugCardView: View {
    let card: DrugCard
    let route: String
    @EnvironmentObject private var content: ContentStore
    @EnvironmentObject private var session: SessionStore

    @State private var weightText = ""
    @State private var ageText = ""
    @State private var obeseOverride = false

    private var resolvedWeight: (kg: Double, estimated: Bool, band: String?)? {
        if let w = Double(weightText), w.isFinite { return (w, false, nil) }
        if let a = Double(ageText), let cfg = content.weightZones,
           let est = WeightZones.estimateWeight(ageYears: a, in: cfg) {
            return (est.weightKg, true, est.band)
        }
        return nil
    }

    /// Obese-child check (Drug_Dosing_Peds_Weight_Based_Spec): needs an actual
    /// weight AND an age, and only acts when this drug opts in via obeseWeightBasis.
    private var obesity: WeightZones.ObesityCheck? {
        guard card.obeseWeightBasis != nil,
              let actual = Double(weightText), let age = Double(ageText),
              let cfg = content.weightZones else { return nil }
        return WeightZones.obesityCheck(actualKg: actual, ageYears: age, in: cfg)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(card.purpose).foregroundStyle(.secondary)
            Text("\(card.population ?? "both") · weight basis: \(card.weightBasis ?? "actual")")
                .font(.caption).foregroundStyle(.secondary)

            ClearableField(label: "Exact weight", unit: "kg", fieldID: "drug-weight", text: Binding(
                get: { weightText }, set: { weightText = $0; session.set(route, "weight", $0) }))
            ClearableField(label: "Age (fallback estimate only)", unit: "years", fieldID: "drug-age", text: Binding(
                get: { ageText }, set: { ageText = $0; session.set(route, "age", $0) }))

            ClearFieldsButton {
                weightText = ""; ageText = ""; session.clearScreen(route)
            }

            Group {
                if let cfg = content.weightZones, let rw = resolvedWeight,
                   let zone = WeightZones.zone(for: rw.kg, in: cfg) {
                    zoneBar(zone, rw)
                    obeseCallout()
                    let dosingKg = dosingWeight(fallback: rw.kg)
                    ForEach(card.doses) { dose in
                        doseRow(dose, weightKg: dosingKg)
                    }
                    Text(cfg.disclaimer).font(.caption2).foregroundStyle(.secondary)
                } else {
                    Text("Enter an exact weight (preferred) or an age to estimate.")
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("dose-output")

            if let c = card.contraindications, !c.isEmpty {
                Text("Contraindications: \(c.joined(separator: "; "))").font(.callout)
            }
            if let r = card.reversal { Text("Reversal: \(r)").font(.callout) }
            BuildNote(text: card.buildNote)
            SourcesBlock(meta: card.meta)
        }
        .task {
            let saved = session.fields(route)
            weightText = saved["weight"] ?? ""
            ageText = saved["age"] ?? ""
        }
    }

    /// The weight the per-kg dose is computed from: ideal body weight when the
    /// obesity flag fires for an "ideal" drug and the user hasn't overridden.
    private func dosingWeight(fallback: Double) -> Double {
        if let ob = obesity, ob.flagged, card.obeseWeightBasis == "ideal", !obeseOverride {
            return ob.ibwKg
        }
        return fallback
    }

    @ViewBuilder private func obeseCallout() -> some View {
        if let ob = obesity, ob.flagged {
            if card.obeseWeightBasis == "ideal" {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Obesity flag — dosing from ideal body weight")
                        .font(.subheadline.bold())
                    Text("Entered weight \(fmt(ob.actualKg)) kg is ~\(ob.pctOver)% above the age-expected weight (\(fmt(ob.ibwKg)) kg). This drug is hydrophilic — actual-weight dosing risks overdose. Doses below use \(obeseOverride ? "actual weight (\(fmt(ob.actualKg)) kg)" : "\(fmt(ob.ibwKg)) kg").")
                        .font(.footnote)
                    Button(obeseOverride ? "Use ideal body weight" : "Use actual weight instead") {
                        obeseOverride.toggle()
                    }
                    .font(.footnote).buttonStyle(.bordered)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .leading) { Rectangle().fill(Color.orange).frame(width: 4) }
            } else if card.obeseWeightBasis == "actual" {
                Text("Entered weight is ~\(ob.pctOver)% above the age-expected weight, but this drug is dosed by total (actual) body weight even in obesity — no adjustment.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private func zoneBar(_ zone: WeightZonesConfig.Zone, _ rw: (kg: Double, estimated: Bool, band: String?)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                HStack(spacing: 6) {
                    if let hex = zone.colorHex {
                        Circle().fill(Color(hex: hex)).frame(width: 9, height: 9)
                            .overlay(Circle().stroke(.black.opacity(0.15), lineWidth: 1))
                    }
                    Text("Zone \(zone.zone) · \(zone.color)")
                }
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color(.separator)))
                if rw.estimated {
                    // estimated weight gets a distinct visual treatment (spec §2)
                    Text("\(fmt(rw.kg)) kg (estimated)").italic().foregroundStyle(.orange)
                } else {
                    Text("\(fmt(rw.kg)) kg")
                }
            }
            Text("ETT \(zone.equipment.ettUncuffed ?? "—") · LMA \(zone.equipment.lma ?? "—") · \(zone.equipment.blade ?? "—")")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private func doseRow(_ dose: DrugCard.Dose, weightKg: Double) -> some View {
        let d = WeightZones.dose(from: dose.rule, weightKg: weightKg)
        return VStack(alignment: .leading, spacing: 3) {
            Text(dose.indication).font(.subheadline.bold())
                + Text(" · \(dose.route)").font(.caption).foregroundColor(.secondary)
            if let d {
                HStack(spacing: 4) {
                    if let hi = d.amountHigh, hi != d.amount {
                        Text("\(fmt(d.amount))–\(fmt(hi)) \(d.unit)").bold()
                    } else {
                        Text("\(fmt(d.amount)) \(d.unit)").bold()
                    }
                    if let v = d.volumeMl {
                        if let vh = d.volumeMlHigh, vh != v {
                            Text("= \(fmt(v))–\(fmt(vh)) mL\(d.concentration.map { " (\($0))" } ?? "")")
                        } else {
                            Text("= \(fmt(v)) mL\(d.concentration.map { " (\($0))" } ?? "")")
                        }
                    }
                    if d.capped { Text("max-dose cap").font(.caption2).foregroundStyle(.orange) }
                    if d.floored { Text("min-dose floor").font(.caption2).foregroundStyle(.orange) }
                }
                if let rep = d.repeatText { Text(rep).font(.caption).foregroundStyle(.secondary) }
            }
            if let n = dose.notes { Text(n).font(.caption).foregroundStyle(.secondary) }
            Divider()
        }
    }

    private func fmt(_ d: Double) -> String {
        d == d.rounded() ? String(Int(d)) : String(format: "%g", d)
    }
}
