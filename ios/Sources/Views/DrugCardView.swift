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

    private var resolvedWeight: (kg: Double, estimated: Bool, band: String?)? {
        if let w = Double(weightText), w.isFinite { return (w, false, nil) }
        if let a = Double(ageText), let cfg = content.weightZones,
           let est = WeightZones.estimateWeight(ageYears: a, in: cfg) {
            return (est.weightKg, true, est.band)
        }
        return nil
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
                    ForEach(card.doses) { dose in
                        doseRow(dose, weightKg: rw.kg)
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
        }
        .task {
            let saved = session.fields(route)
            weightText = saved["weight"] ?? ""
            ageText = saved["age"] ?? ""
        }
    }

    private func zoneBar(_ zone: WeightZonesConfig.Zone, _ rw: (kg: Double, estimated: Bool, band: String?)) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Zone \(zone.zone) · \(zone.color)")
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .overlay(Capsule().stroke(Color.accentColor))
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
