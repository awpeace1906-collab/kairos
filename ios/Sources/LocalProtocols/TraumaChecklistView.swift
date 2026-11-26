import SwiftUI
import TraumaCore

/// Bedside checklist for one local trauma-activation profile. Every criterion,
/// tier, team list and response time comes from the profile; checks and
/// vitals live in @State for this screen only (Clear resets them; nothing is
/// saved). Result: highest tier met, never "No activation".
struct TraumaChecklistView: View {
    @ObservedObject var store: LocalProtocolStore
    @EnvironmentObject private var content: ContentStore
    @State var profileId: String
    @State private var checked: Set<String> = []
    @State private var vitalText: [String: String] = [:]
    @State private var expanded = false
    @FocusState private var focus: String?

    private var entry: LibraryEntry? { store.entry(profileId) }

    var body: some View {
        Group {
            if let entry {
                let model = ProfileModel(raw: entry.profile)
                let result = evaluate(entry.profile)
                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        header(model)
                        if !model.vitals.isEmpty { vitalsStrip(model) }
                        criteriaList(model, result)
                        Button("Clear") { checked = []; vitalText = [:]; focus = nil }
                            .buttonStyle(.bordered).tint(.secondary)
                            .accessibilityIdentifier("trauma-clear")
                        if let acs = content.searchIndex.entries.first(where: { $0.itemID == "acs-field-triage-link" }) {
                            NavigationLink(value: Route.content(acs.route)) {
                                Label(acs.title, systemImage: "arrow.up.right.square").font(Theme.callout)
                            }
                        }
                    }
                    .padding()
                    .padding(.bottom, 90)
                }
                .safeAreaInset(edge: .bottom) { resultBar(model, result) }
            } else {
                ContentUnavailableViewCompat(text: "This profile is no longer in the library.")
            }
        }
        // The bedside result bar needs the bottom edge; the floating tab bar would cover it.
        .toolbar(.hidden, for: .tabBar)
        .navigationTitle(entry.map { ProfileModel(raw: $0.profile).institution } ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) { switcher }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { focus = nil } label: { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent) }
                    .accessibilityLabel("Done")
            }
        }
    }

    // MARK: - Engine

    private func vitals(_ model: ProfileModel) -> [String: Double] {
        var out: [String: Double] = [:]
        for v in model.vitals {
            let t = (vitalText[v.id] ?? "").trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
            if !t.isEmpty { out[v.id] = Double(t) ?? .nan }
        }
        return out
    }

    private func evaluate(_ profile: JSONValue) -> TraumaResult? {
        try? traumaEvaluate(profile: profile, input: TraumaInput(checked: Array(checked), vitals: vitals(ProfileModel(raw: profile))))
    }

    // MARK: - Header + switcher

    private func header(_ m: ProfileModel) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(m.institution).font(Theme.headline)
            HStack(spacing: 6) {
                Text(m.revisionDate).font(Theme.mono(12))
                if let ago = m.revisedAgo { Text("· \(ago)").font(Theme.caption) }
                if !store.isCurrent(m.profileId) { Text("· superseded").font(Theme.caption).foregroundStyle(Theme.severityColor("high")) }
            }
            .foregroundStyle(.secondary)
            if let banner = m.bannerText {
                Text(banner).font(Theme.footnote).modifier(BandStyle(severity: "moderate"))
                    .accessibilityIdentifier("trauma-banner")
            }
            if let applies = m.appliesTo { Text(applies).font(Theme.footnote).foregroundStyle(.secondary) }
        }
    }

    private var switcher: some View {
        Menu {
            ForEach(store.groups, id: \.currentProfileId) { g in
                Button {
                    profileId = g.currentProfileId; checked = []; vitalText = [:]
                } label: {
                    if g.versions.contains(where: { $0.profileId == profileId }) { Label(g.institution, systemImage: "checkmark") }
                    else { Text(g.institution) }
                }
            }
        } label: {
            Image(systemName: "building.2")
        }
        .accessibilityLabel("Switch facility")
        .accessibilityIdentifier("trauma-switcher")
    }

    // MARK: - Vitals

    private func vitalsStrip(_ m: ProfileModel) -> some View {
        let cols = [GridItem(.adaptive(minimum: 96), spacing: 8)]
        return LazyVGrid(columns: cols, alignment: .leading, spacing: 8) {
            ForEach(m.vitals) { v in
                VStack(alignment: .leading, spacing: 2) {
                    Text(v.unit.isEmpty ? v.label : "\(v.label) (\(v.unit))").font(Theme.caption2).foregroundStyle(.secondary)
                    TextField("", text: Binding(get: { vitalText[v.id] ?? "" }, set: { vitalText[v.id] = $0 }))
                        .keyboardType(.decimalPad)
                        .focused($focus, equals: v.id)
                        .font(Theme.mono(15))
                        .padding(6)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        .accessibilityLabel(v.label)
                        .accessibilityIdentifier("trauma-vital-\(v.id)")
                }
            }
        }
    }

    // MARK: - Criteria

    private func criteriaList(_ m: ProfileModel, _ r: TraumaResult?) -> some View {
        let auto = Set((r?.met ?? []).filter { $0.source == "auto" }.map(\.id))
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(m.grouped, id: \.tier.id) { block in
                VStack(alignment: .leading, spacing: 8) {
                    Text(block.tier.label)
                        .font(Theme.semibold(15)).padding(.horizontal, 10).padding(.vertical, 4)
                        .background(Color(hex: block.tier.color), in: Capsule())
                        .foregroundStyle(Color.onTier(block.tier.color))
                    ForEach(block.sections, id: \.section) { sec in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(sec.section.uppercased()).font(Theme.mono(11)).tracking(0.6).foregroundStyle(.secondary)
                            ForEach(sec.groups, id: \.group) { grp in
                                if grp.group != sec.section { Text(grp.group).font(Theme.semibold(14)) }
                                ForEach(grp.items) { c in row(c, auto: auto.contains(c.id)) }
                            }
                        }
                    }
                }
            }
        }
    }

    private func row(_ c: ProfileModel.Criterion, auto: Bool) -> some View {
        let on = checked.contains(c.id) || auto
        return Button {
            if checked.contains(c.id) { checked.remove(c.id) } else { checked.insert(c.id) }
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: on ? "checkmark.square.fill" : "square").foregroundStyle(on ? Theme.accent : .secondary)
                VStack(alignment: .leading, spacing: 2) {
                    if let base = c.compoundBaseText {
                        Text(base).font(Theme.callout)
                        Text(c.text).font(Theme.caption).foregroundStyle(.secondary)
                    } else {
                        Text(c.text).font(Theme.callout)
                    }
                    if auto, let label = c.autoLabel { Text("auto: \(label)").font(Theme.mono(11)).foregroundStyle(Theme.accent) }
                }
                Spacer(minLength: 0)
            }
            .padding(8)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityIdentifier("trauma-row-\(c.id)")
    }

    // MARK: - Result bar

    @ViewBuilder private func resultBar(_ m: ProfileModel, _ r: TraumaResult?) -> some View {
        let tier = m.tier(r?.tier)
        let bg = tier.map { Color(hex: $0.color) } ?? Color(.secondarySystemBackground)
        let fg = tier.map { Color.onTier($0.color) } ?? Color.primary
        VStack(alignment: .leading, spacing: 6) {
            Button { withAnimation(.easeOut(duration: 0.15)) { expanded.toggle() } } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        if let r, r.status == "error" {
                            ForEach(Array(r.errors.enumerated()), id: \.offset) { _, e in Text(e.text).font(Theme.callout) }
                        } else {
                            Text(tier?.label ?? "No criteria selected").font(Theme.semibold(18))
                            if let rt = tier?.responseTime { Text(rt).font(Theme.footnote) }
                        }
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.down" : "chevron.up")
                }
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("trauma-result")
            if expanded, let r, r.status == "ok" {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        if let team = tier?.teamResponse, !team.isEmpty {
                            ForEach(team, id: \.self) { Text("• \($0)").font(Theme.footnote) }
                        }
                        let byId = Dictionary(uniqueKeysWithValues: m.criteria.map { ($0.id, $0) })
                        ForEach(r.met, id: \.id) { mt in
                            Text("✓ \(byId[mt.id]?.text ?? mt.id)").font(Theme.footnote)
                        }
                        ForEach(r.compoundHints, id: \.id) { Text($0.text).font(Theme.footnote).italic() }
                        ForEach(r.notes, id: \.id) { Text($0.text).font(Theme.footnote) }
                        ForEach(r.advisories, id: \.id) { Text($0.text).font(Theme.footnote).bold() }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 260)
            }
        }
        .foregroundStyle(fg)
        .padding(12)
        .background(bg)
    }
}
