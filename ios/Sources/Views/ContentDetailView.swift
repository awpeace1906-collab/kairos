import SwiftUI

struct ContentDetailView: View {
    let route: String
    @EnvironmentObject private var content: ContentStore
    @AppStorage(Pins.key) private var pinsRaw = ""
    @State private var loaded: Loaded?
    @State private var error: String?

    enum Loaded {
        case calculator(Calculator)
        case reference(ReferenceDoc)
        case procedure(Procedure)
        case drugCard(DrugCard)
        case anesthesiaDrugCard(AnesthesiaDrugCard)
        case pedsTool(PedsTool)

        var meta: RecordMeta {
            switch self {
            case .calculator(let m): return m.meta
            case .reference(let m):  return m.meta
            case .procedure(let m):  return m.meta
            case .drugCard(let m):   return m.meta
            case .anesthesiaDrugCard(let m): return m.meta
            case .pedsTool(let m):   return m.meta
            }
        }
    }

    var body: some View {
        Group {
            if let error {
                ContentUnavailableViewCompat(text: error)
            } else if let loaded {
                let tint = Theme.sectionColor(forTitle: loaded.meta.section)
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Rectangle()
                            .fill(tint)
                            .frame(maxWidth: .infinity, minHeight: 3, maxHeight: 3)
                        VStack(alignment: .leading, spacing: 16) {
                            Text(loaded.meta.section.uppercased())
                                .font(Theme.mono(11)).tracking(1.2)
                                .foregroundStyle(tint)
                            switch loaded {
                            case .calculator(let c): CalculatorView(calc: c, route: route)
                            case .reference(let r):  ReferenceBody(doc: r)
                            case .procedure(let p):  ProcedureBody(proc: p)
                            case .drugCard(let d):   DrugCardView(card: d, route: route)
                            case .anesthesiaDrugCard(let a): AnesthesiaDrugCardBody(card: a)
                            case .pedsTool(let t):   PedsToolBody(tool: t, route: route)
                            }
                            LastVerified(meta: loaded.meta)
                        }
                        .padding()
                    }
                }
                .transition(.opacity)
            } else {
                ProgressView()
            }
        }
        .animation(.easeOut(duration: 0.18), value: loaded == nil)
        .navigationTitle(loaded?.meta.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let id = loaded?.meta.id {
                let on = Pins.isPinned(id, raw: pinsRaw, curated: content.curatedPinIds)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        pinsRaw = Pins.toggled(id, raw: pinsRaw, curated: content.curatedPinIds)
                    } label: {
                        Image(systemName: on ? "pin.fill" : "pin")
                    }
                    .accessibilityLabel(on ? "Unpin" : "Pin to home")
                    .tint(on ? Theme.accent : nil)
                }
            }
        }
        .task(id: route) { await load() }
    }

    private func load() async {
        do {
            let (entry, data) = try content.loadModuleData(forRoute: route)
            switch entry.contentType {
            case .calculator: loaded = .calculator(try content.decode(Calculator.self, from: data))
            case .reference:  loaded = .reference(try content.decode(ReferenceDoc.self, from: data))
            case .procedure:  loaded = .procedure(try content.decode(Procedure.self, from: data))
            case .drugCard:   loaded = .drugCard(try content.decode(DrugCard.self, from: data))
            case .anesthesiaDrugCard: loaded = .anesthesiaDrugCard(try content.decode(AnesthesiaDrugCard.self, from: data))
            case .pedsTool:   loaded = .pedsTool(try content.decode(PedsTool.self, from: data))
            }
        } catch {
            self.error = "\(error)"
        }
    }
}

// MARK: - Reference

struct ReferenceBody: View {
    let doc: ReferenceDoc
    private var tint: Color { Theme.sectionColor(forTitle: doc.meta.section) }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let summary = doc.summary {
                RichText(summary).foregroundStyle(.secondary)
            }
            if let why = doc.whyThisMatters {
                framedNote("WHY THIS MATTERS", why)
            }
            BlockList(blocks: doc.body, sectionTint: tint)
            if let take = doc.clinicalTakeaway {
                framedNote("CLINICAL TAKEAWAY", take, emphasized: true)
            }
            BuildNote(text: doc.buildNote)
            SourcesBlock(meta: doc.meta)
        }
    }

    // WHY THIS MATTERS is quiet context; CLINICAL TAKEAWAY is the one struck
    // point — ember bar, ember label, ember-tinted ground. Mirrors web.
    @ViewBuilder private func framedNote(_ label: String, _ text: String, emphasized: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(Theme.mono(11)).tracking(0.8)
                .foregroundStyle(emphasized ? Theme.accent : Color.secondary)
            RichText(text).font(Theme.callout).fontWeight(emphasized ? .medium : .regular)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            emphasized ? Theme.accent.opacity(0.10) : Color(.tertiarySystemBackground),
            in: RoundedRectangle(cornerRadius: 10)
        )
        .overlay(alignment: .leading) {
            Rectangle().fill(emphasized ? Theme.accent : Color(.separator))
                .frame(width: emphasized ? 3 : 2)
        }
    }
}

/// Shared renderer for the `body` block array (reference + peds-tool modules).
struct BlockList: View {
    let blocks: [ReferenceDoc.Block]
    var sectionTint: Color = .accentColor
    var body: some View {
        ForEach(Array(blocks.enumerated()), id: \.offset) { i, b in
            block(b, isFirst: i == 0)
        }
    }

    /// Single-level bullet for plain `[String]` fields (checklists, notes).
    /// Nested lists go through `ContentListView`, which shares the same
    /// lead-term bolding.
    private func listItemText(_ s: String) -> Text {
        ContentListView.line(marker: "\u{2022}", text: s)
    }

    @ViewBuilder private func block(_ b: ReferenceDoc.Block, isFirst: Bool) -> some View {
        switch b.type {
        case "heading":
            if b.level == 2 {
                VStack(alignment: .leading, spacing: 7) {
                    if !isFirst { Divider() }
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        RoundedRectangle(cornerRadius: 1.5).fill(sectionTint)
                            .frame(width: 3, height: 15)
                        Text(b.text ?? "").font(Theme.display(19))
                    }
                }
                .padding(.top, isFirst ? 0 : 10)
            } else {
                Text(b.text ?? "").font(Theme.display(16))
            }
        case "text":
            RichText(b.text ?? "")
        case "list":
            ContentListView(items: b.items ?? [], ordered: b.ordered ?? false)
        case "callout":
            RichText(b.text ?? "")
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(calloutColor(b.tone).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .leading) { Rectangle().fill(calloutColor(b.tone)).frame(width: 4) }
        case "table":
            TableBlock(columns: b.columns ?? [], rows: b.rows ?? [])
        case "diagram":
            if let d = b.diagram { DiagramView(diagram: d) }
        default:
            EmptyView()
        }
    }

    private func calloutColor(_ tone: String?) -> Color {
        switch tone { case "danger": return .red; case "warning": return .orange; default: return .blue }
    }
}

// MARK: - Procedure

struct ProcedureBody: View {
    let proc: Procedure
    private var isTree: Bool { proc.outputType == "decision-tree" && !(proc.nodes ?? []).isEmpty }
    private var numberedNodes: [(node: Procedure.Node, badge: String)] {
        var n = 0
        return (proc.nodes ?? []).map { node in
            let isWarning = node.type == "warning"
            if !isWarning { n += 1 }
            return (node, isWarning ? "!" : String(n))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RichText(proc.purpose).foregroundStyle(.secondary)
            Text(proc.outputType.uppercased() + (proc.meta.flags?.contains("stub") == true ? " · STUB" : ""))
                .font(Theme.caption).foregroundStyle(.secondary)
            if let prompt = proc.entryPrompt { Text(prompt).font(Theme.headline) }

            if isTree {
                ProcedureWalker(nodes: proc.nodes ?? [])
            } else {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(numberedNodes, id: \.node.id) { item in
                        WorkflowNodeCard(node: item.node, badge: item.badge)
                    }
                }
            }

            if let checklist = proc.checklist, !checklist.isEmpty {
                Text("Checklist").font(Theme.headline)
                ForEach(checklist, id: \.self) { Text("☐ \($0)") }
            }
            if let tmpl = proc.noteTemplate {
                Text("Procedure note template").font(Theme.headline)
                Text(tmpl).font(Theme.mono(13))
                    .padding(10).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            if let x = proc.crossLinks, !x.isEmpty {
                Text("Orchestrates: \(x.joined(separator: ", "))").font(Theme.footnote).foregroundStyle(.secondary)
            }
            BuildNote(text: proc.buildNote)
            SourcesBlock(meta: proc.meta)
        }
    }
}

/// One step in a static (non-tree) procedure workflow — a numbered card, or a
/// warning-badged card for an at-any-point caution (e.g. CICO, LAST).
struct WorkflowNodeCard: View {
    let node: Procedure.Node
    let badge: String
    private var isWarning: Bool { node.type == "warning" }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(badge)
                .font(Theme.mono(13)).fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(isWarning ? Theme.severityColor("high") : Theme.accent, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                if let p = node.prompt { Text(p).font(Theme.subheadline).fontWeight(.semibold) }
                if let b = node.body { RichText(b).font(Theme.callout) }
                if let sub = node.substeps {
                    ContentListView(items: sub.items, ordered: sub.ordered)
                        .font(Theme.callout)
                }
                if let d = node.diagram { DiagramView(diagram: d) }
            }
        }
        .padding(13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            isWarning ? Theme.severityColor("high").opacity(0.12) : Color(.secondarySystemBackground),
            in: RoundedRectangle(cornerRadius: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWarning ? Theme.severityColor("high").opacity(0.4) : Color(.separator), lineWidth: 1)
        )
    }
}

/// Interactive walk of a decision-tree procedure.
struct ProcedureWalker: View {
    let nodes: [Procedure.Node]
    private var byId: [String: Procedure.Node] { Dictionary(uniqueKeysWithValues: nodes.map { ($0.id, $0) }) }
    private var startId: String { byId["start"] != nil ? "start" : (nodes.first { $0.type == "question" } ?? nodes[0]).id }
    @State private var path: [String] = []

    var body: some View {
        let current = path.last.flatMap { byId[$0] } ?? byId[startId]
        VStack(alignment: .leading, spacing: 10) {
            if path.count > 1 {
                Text(path.compactMap { byId[$0]?.prompt ?? byId[$0]?.body?.prefix(20).description }.joined(separator: " › "))
                    .font(Theme.caption2).foregroundStyle(.secondary)
            }
            if let node = current {
                if let p = node.prompt { Text(p).font(Theme.headline) }
                if let b = node.body {
                    RichText(b)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((node.type == "warning" ? Color.red : Color.green).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .leading) { Rectangle().fill(node.type == "warning" ? Color.red : Color.green).frame(width: 3) }
                }
                if let sub = node.substeps {
                    ContentListView(items: sub.items, ordered: sub.ordered)
                        .font(Theme.callout)
                }
                if let choices = node.choices, !choices.isEmpty {
                    ForEach(choices, id: \.label) { c in
                        Button {
                            path.append(c.next)
                        } label: {
                            HStack { Text(c.label); Spacer(); Image(systemName: "chevron.right") }
                                .padding(10)
                                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("tree-choice-\(c.next)")
                    }
                } else {
                    Text("End of this branch.").font(Theme.footnote).foregroundStyle(.secondary)
                        .accessibilityIdentifier("tree-end")
                }
            }
            if path.count > 1 {
                HStack {
                    Button("‹ Back") { path.removeLast() }.buttonStyle(.bordered)
                    Button("Start over") { path = [startId] }.buttonStyle(.bordered)
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.5), in: RoundedRectangle(cornerRadius: 10))
        .onAppear { if path.isEmpty { path = [startId] } }
    }
}

// MARK: - Peds tool

struct PedsToolBody: View {
    let tool: PedsTool
    let route: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RichText(tool.purpose).foregroundStyle(.secondary)
            if let age = tool.ageRange { Text(age).font(Theme.caption).foregroundStyle(.secondary) }
            if let embedded = tool.embeddedCalculator {
                CalculatorView(calc: embedded, route: route)
            } else if let src = tool.sourceOfTruth, !src.isEmpty {
                Text("Defers to: \(src.joined(separator: ", "))").font(Theme.footnote).foregroundStyle(.secondary)
            }
            if let body = tool.body, !body.isEmpty {
                BlockList(blocks: body, sectionTint: Theme.sectionColor(forTitle: tool.meta.section))
            }
            BuildNote(text: tool.buildNote)
            if tool.embeddedCalculator == nil { SourcesBlock(meta: tool.meta) }
        }
    }
}

// MARK: - Anesthesia drug card (AnesCalc-origin)

struct AnesthesiaDrugCardBody: View {
    let card: AnesthesiaDrugCard
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(card.tallManLetters ?? card.meta.title).font(Theme.headline)
                if let b = card.brandName { Text("· \(b)").foregroundStyle(.secondary) }
            }
            Text(card.drugClassLabel).font(Theme.caption).foregroundStyle(.secondary)
            RichText(card.mechanism).foregroundStyle(.secondary)

            HStack(spacing: 20) {
                labeled("Onset", card.onset)
                labeled("Duration", card.duration)
            }
            if let r = card.reversal { labeled("Reversal", r) }

            group("Dosing") {
                VStack(alignment: .leading, spacing: 0) {
                    let lines = card.dosing.split(separator: "\n").map(String.init)
                    ForEach(Array(lines.enumerated()), id: \.offset) { i, line in
                        dosingRow(line)
                        if i < lines.count - 1 { Divider() }
                    }
                }
            }
            group("Cautions") { bullets(card.cautions) }
            group("Pearls") { bullets(card.pearls) }
            SourcesBlock(meta: card.meta)
        }
    }

    @ViewBuilder private func dosingRow(_ line: String) -> some View {
        if let range = line.range(of: ": ") {
            VStack(alignment: .leading, spacing: 3) {
                Text(line[line.startIndex..<range.lowerBound]).font(Theme.semibold(15, relativeTo: .subheadline))
                Text(line[range.upperBound...]).font(Theme.callout)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(line).font(Theme.callout).padding(.vertical, 8)
        }
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(Theme.caption2).foregroundStyle(.secondary)
            Text(value).font(Theme.callout)
        }
    }
    @ViewBuilder private func group<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        Text(title).font(Theme.headline).padding(.top, 4)
        content()
    }
    private func bullets(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Marker in its own column so a long caution hangs under its text;
            // each item may carry the Kairos text format (RichText).
            ForEach(items, id: \.self) { item in
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("•")
                    RichText(item)
                }
                .font(Theme.callout)
            }
        }
    }
}

struct BuildNote: View {
    let text: String?
    var body: some View {
        if let text {
            DisclosureGroup("Build note") {
                Text(text).font(Theme.footnote).foregroundStyle(.secondary)
            }
            .font(Theme.footnote)
        }
    }
}
