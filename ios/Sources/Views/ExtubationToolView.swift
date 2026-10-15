import SwiftUI
import ExtubationEngine

/// Extubation Decision Tool (engine: builtin, tool: extubation). Every screen,
/// word, rule and citation comes from the bundled kit file
/// extubation-logic.json at runtime; this view only lays it out in Kairos's
/// skin. Navigation is derived from extubationEvaluate(): screensShown gives
/// the next and previous screen, and a stop outcome whose last shown screen is
/// the current one means its stopIf fired. Answers live in @State only, so
/// nothing is saved and leaving the tool discards them (no SessionStore).
/// Mirrors web/src/views/extubationTool.js.
struct ExtubationToolView: View {
    static let setting = "setting"

    @State private var logic: ExtubationLogic?
    @State private var loadFailed = false
    @State private var answers = ExtubationAnswers()
    /// A screen id, or nil for the result.
    @State private var current: String? = ExtubationToolView.setting
    /// alert id -> item ids listed when it was acknowledged.
    @State private var acks: [String: Set<String>] = [:]
    @State private var pending: PendingConfirm?
    @State private var cardPDF: Data?
    @FocusState private var focus: String?

    struct Choice: Identifiable { let id: String; let label: String }

    enum PendingConfirm: Identifiable {
        case startOver
        case changeSetting(String)
        var id: String {
            switch self {
            case .startOver: return "startOver"
            case .changeSetting(let s): return "setting-\(s)"
            }
        }
    }

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
        guard let url = Bundle.main.url(forResource: "extubation-logic", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let parsed = try? ExtubationLogic.load(from: data) else { loadFailed = true; return }
        logic = parsed
    }

    // MARK: - Engine-derived state

    private func evaluate(_ logic: ExtubationLogic) -> ExtubationResult? {
        answers.setting.isEmpty ? nil : try? extubationEvaluate(logic: logic, answers: answers)
    }

    private func screenAlerts(_ logic: ExtubationLogic, _ screenId: String) -> [AlertResult] {
        (evaluate(logic)?.alerts ?? []).filter { a in
            a.requiresAck && logic.alerts[a.id].flatMap(extubationAlertOwnerScreenId) == screenId
        }
    }

    private func canAdvance(_ logic: ExtubationLogic, _ sc: ExtubationScreen) -> Bool {
        if sc.required == true {
            switch sc.type {
            case .textFields:
                let vals = answers.textFields[sc.id] ?? [:]
                if !(sc.fields ?? []).allSatisfy({ !(vals[$0.id] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) { return false }
            case .singleChoice, .yesNo:
                if (answers.answer(sc.id) ?? "").isEmpty { return false }
            case .checklist:
                break
            }
        }
        return screenAlerts(logic, sc.id).allSatisfy { acks[$0.id] != nil }
    }

    /// An acknowledgment holds while the alert's list stays the same or shrinks;
    /// a new item clears it (alertRules).
    private func refreshAcks(_ logic: ExtubationLogic) {
        for (id, ackedItems) in acks {
            let now = extubationAlertItemIds(logic: logic, answers: answers, alertId: id)
            if !now.isSubset(of: ackedItems) { acks[id] = nil }
        }
    }

    // MARK: - Navigation

    private func next(_ logic: ExtubationLogic) {
        guard let id = current, let sc = logic.screen(id), canAdvance(logic, sc),
              let r = evaluate(logic) else { return }
        focus = nil
        if id == Self.setting { current = r.screensShown.first; return }
        if let i = r.screensShown.firstIndex(of: id), i + 1 < r.screensShown.count {
            current = r.screensShown[i + 1]
        } else {
            current = nil
        }
    }

    private func back(_ logic: ExtubationLogic) {
        focus = nil
        let shown = evaluate(logic)?.screensShown ?? []
        guard let id = current else { current = shown.last; return }
        if let i = shown.firstIndex(of: id), i > 0 { current = shown[i - 1] } else { current = Self.setting }
    }

    private func clearAll() {
        answers = ExtubationAnswers(); acks = [:]; cardPDF = nil; current = Self.setting
    }

    private func perform(_ c: PendingConfirm) {
        switch c {
        case .startOver: clearAll()
        case .changeSetting(let s): clearAll(); answers.setting = s
        }
    }

    // MARK: - Layout

    @ViewBuilder private func tool(_ logic: ExtubationLogic) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let id = current, let sc = logic.screen(id) {
                screen(logic, sc)
            } else if let r = evaluate(logic) {
                result(logic, r)
            }
        }
        .alert(pendingMessage(logic), isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } }), presenting: pending) { item in
            Button(logic.ui.buttons.cancel, role: .cancel) {}
            Button(logic.ui.buttons.confirm, role: .destructive) { perform(item) }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button { focus = nil } label: { Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.accent) }
                    .accessibilityLabel("Done")
            }
        }
    }

    private func pendingMessage(_ logic: ExtubationLogic) -> String {
        switch pending {
        case .changeSetting: return logic.ui.buttons.resetConfirm
        default: return logic.ui.buttons.startOverConfirm
        }
    }

    private func topBar(_ logic: ExtubationLogic, step: Int?) -> some View {
        let t = logic.tracks[answers.setting]
        return HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(t?.title ?? "").font(Theme.headline)
                if let step, let t {
                    Text(logic.ui.stepLabel
                        .replacingOccurrences(of: "{current}", with: String(step))
                        .replacingOccurrences(of: "{total}", with: String(t.totalSteps)))
                    .font(Theme.mono(12)).foregroundStyle(.secondary)
                    .accessibilityIdentifier("ext-step")
                }
            }
            Spacer()
            Button(logic.ui.buttons.reset) { pending = .startOver }
                .buttonStyle(.bordered).tint(.secondary)
                .accessibilityIdentifier("ext-reset")
        }
        .padding(.bottom, 6)
        .overlay(alignment: .bottom) { Divider() }
    }

    // MARK: Screen

    @ViewBuilder private func screen(_ logic: ExtubationLogic, _ sc: ExtubationScreen) -> some View {
        if sc.id != Self.setting { topBar(logic, step: sc.step) } // flowRules: step 0 has no top bar
        Text(sc.title).font(Theme.title3).accessibilityIdentifier("ext-title")
        Text(sc.prompt).font(Theme.callout)
        if let info = sc.info {
            VStack(alignment: .leading, spacing: 4) {
                Text(info).font(Theme.callout)
                if let keys = sc.infoSources, !keys.isEmpty {
                    Text(keys.compactMap { logic.sources[$0]?.short }.joined(separator: " · "))
                        .font(Theme.caption).foregroundStyle(.secondary)
                }
            }
            .modifier(BandStyle(severity: nil))
        }
        control(logic, sc)
        if let note = sc.note { Text(note).font(Theme.footnote).foregroundStyle(.secondary) }
        ForEach(screenAlerts(logic, sc.id), id: \.id) { alertBox(logic, $0, informational: false) }
        if sc.id == Self.setting { Text(logic.ui.disclaimer).font(Theme.footnote).foregroundStyle(.secondary) }
        HStack {
            Button(logic.ui.buttons.back) { back(logic) }
                .buttonStyle(.bordered).tint(.secondary)
                .disabled(sc.id == Self.setting)
                .accessibilityIdentifier("ext-back")
            Spacer()
            Button(logic.ui.buttons.next) { next(logic) }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
                .disabled(!canAdvance(logic, sc))
                .accessibilityIdentifier("ext-next")
        }
        .padding(.top, 6)
    }

    @ViewBuilder private func control(_ logic: ExtubationLogic, _ sc: ExtubationScreen) -> some View {
        switch sc.type {
        case .singleChoice:
            choices(logic, sc, (sc.options ?? []).map { Choice(id: $0.id, label: $0.label) })
        case .yesNo:
            choices(logic, sc, [Choice(id: "yes", label: logic.ui.buttons.yes), Choice(id: "no", label: logic.ui.buttons.no)])
        case .checklist:
            VStack(spacing: 6) {
                ForEach(sc.items ?? []) { it in
                    let on = answers.checked(sc.id).contains(it.id)
                    Button {
                        var set = answers.checked(sc.id)
                        if on { set.remove(it.id) } else { set.insert(it.id) }
                        answers.checklists[sc.id] = set
                        refreshAcks(logic)
                    } label: {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Image(systemName: on ? "checkmark.square.fill" : "square")
                                .foregroundStyle(on ? Theme.accent : .secondary)
                            Text(it.label).font(Theme.callout).multilineTextAlignment(.leading)
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(on ? .isSelected : [])
                    .accessibilityIdentifier("ext-check-\(sc.id)-\(it.id)")
                }
            }
        case .textFields:
            VStack(alignment: .leading, spacing: 12) {
                ForEach(sc.fields ?? []) { f in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(f.label).font(Theme.caption).foregroundStyle(.secondary)
                        TextField("", text: Binding(
                            get: { answers.textFields[sc.id]?[f.id] ?? "" },
                            set: { answers.textFields[sc.id, default: [:]][f.id] = $0 }))
                        .focused($focus, equals: "\(sc.id).\(f.id)")
                        .font(Theme.callout)
                        .textInputAutocapitalization(.sentences)
                        .padding(10)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel(f.label)
                        .accessibilityIdentifier("ext-field-\(sc.id)-\(f.id)")
                    }
                }
            }
        }
    }

    private func choices(_ logic: ExtubationLogic, _ sc: ExtubationScreen, _ options: [Choice]) -> some View {
        VStack(spacing: 8) {
            ForEach(options) { o in
                let on = answers.answer(sc.id) == o.id
                Button { pick(logic, sc, o.id) } label: {
                    Text(o.label).font(Theme.headline)
                        .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                        .padding(.horizontal, 6)
                }
                .buttonStyle(.bordered)
                .tint(on ? Theme.accent : .secondary)
                .background(on ? Theme.accent.opacity(0.14) : .clear, in: RoundedRectangle(cornerRadius: 8))
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityIdentifier("ext-choice-\(sc.id)-\(o.id)")
            }
        }
    }

    private func pick(_ logic: ExtubationLogic, _ sc: ExtubationScreen, _ id: String) {
        if sc.id == Self.setting {
            let hasOther = !answers.checklists.isEmpty || !answers.choices.isEmpty || !answers.textFields.isEmpty
            if !answers.setting.isEmpty, answers.setting != id, hasOther { pending = .changeSetting(id); return }
            answers.setting = id
        } else {
            answers.choices[sc.id] = id
        }
    }

    private func alertBox(_ logic: ExtubationLogic, _ a: AlertResult, informational: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(a.text).font(Theme.callout)
            if a.requiresAck {
                let on = acks[a.id] != nil
                Button {
                    acks[a.id] = on ? nil : extubationAlertItemIds(logic: logic, answers: answers, alertId: a.id)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: on ? "checkmark.square.fill" : "square")
                        Text(logic.ui.acknowledge).font(Theme.callout)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityIdentifier("ext-ack-\(a.id)")
            }
        }
        .modifier(BandStyle(severity: a.level == "red" ? "high" : "moderate"))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("ext-alert-\(a.id)")
    }

    // MARK: Result (order follows resultLayout; no section headings, per layoutRules)

    private func severity(_ r: ExtubationResult) -> String {
        r.outcomeClass == "stop" ? "high" : r.outcomeClass == "high" ? "moderate" : "low"
    }

    private func rescuePairs(_ logic: ExtubationLogic, _ r: ExtubationResult) -> [RescueLine] {
        guard let sc = r.screensShown.compactMap({ logic.screen($0) }).first(where: { $0.type == .textFields }),
              let vals = answers.textFields[sc.id] else { return [] }
        return (sc.fields ?? []).map { RescueLine(id: $0.id, label: $0.label, value: vals[$0.id] ?? "") }
    }

    @ViewBuilder private func result(_ logic: ExtubationLogic, _ r: ExtubationResult) -> some View {
        let sev = severity(r)
        topBar(logic, step: nil)
        Text(r.chip)
            .font(Theme.mono(12)).foregroundStyle(Theme.severityColor(sev))
            .padding(.horizontal, 10).padding(.vertical, 4)
            .overlay(Capsule().stroke(Theme.severityColor(sev)))
            .accessibilityIdentifier("ext-chip")
        Text(r.title).font(Theme.title3)
        Text(r.recommendation).font(Theme.callout).fontWeight(.medium).modifier(BandStyle(severity: sev))
        ForEach(r.alerts, id: \.id) { alertBox(logic, $0, informational: true) }
        if !r.why.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                ForEach(r.why, id: \.self) { w in
                    HStack(alignment: .firstTextBaseline, spacing: 6) { Text("•"); Text(w) }.font(Theme.callout)
                }
            }
        }
        let pairs = rescuePairs(logic, r)
        if !pairs.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(pairs) { p in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(p.label).font(Theme.caption).foregroundStyle(.secondary)
                        Text(p.value).font(Theme.callout)
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        DisclosureGroup(logic.ui.buttons.evidence) {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(Array(r.sources.enumerated()), id: \.offset) { i, k in
                    Text("\(i + 1). \(logic.sources[k]?.full ?? k)").font(Theme.footnote)
                }
            }
            .padding(.top, 4)
        }
        .font(Theme.callout)
        Text(logic.ui.disclaimer).font(Theme.footnote).foregroundStyle(.secondary)
        HStack {
            Button(logic.ui.buttons.back) { back(logic) }
                .buttonStyle(.bordered).tint(.secondary)
                .accessibilityIdentifier("ext-back")
            Spacer()
            if let pdf = cardPDF {
                ShareLink(item: HandoffCardPDF(data: pdf), preview: SharePreview(logic.ui.card.header)) {
                    Text(logic.ui.buttons.print)
                }
                .buttonStyle(.borderedProminent).tint(Theme.accent)
                .accessibilityIdentifier("ext-share")
            }
            Button(logic.ui.buttons.reset) { pending = .startOver }
                .buttonStyle(.bordered).tint(.secondary)
        }
        .onAppear { cardPDF = makeCardPDF(logic, r) }
    }

    @MainActor private func makeCardPDF(_ logic: ExtubationLogic, _ r: ExtubationResult) -> Data? {
        let card = ExtubationCardView(
            logic: logic, result: r,
            trackTitle: logic.tracks[answers.setting]?.title ?? "",
            rescue: rescuePairs(logic, r),
            date: Date())
        return HandoffCardPDF.render(card)
    }
}
