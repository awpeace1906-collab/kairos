import SwiftUI

struct ContentDetailView: View {
    let route: String
    @EnvironmentObject private var content: ContentStore
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
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
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
            } else {
                ProgressView()
            }
        }
        .navigationTitle(loaded?.meta.title ?? "")
        .navigationBarTitleDisplayMode(.inline)
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let summary = doc.summary {
                Text(summary).foregroundStyle(.secondary)
            }
            BlockList(blocks: doc.body)
            BuildNote(text: doc.buildNote)
        }
    }
}

/// Shared renderer for the `body` block array (reference + peds-tool modules).
struct BlockList: View {
    let blocks: [ReferenceDoc.Block]
    var body: some View {
        ForEach(Array(blocks.enumerated()), id: \.offset) { _, b in
            block(b)
        }
    }

    @ViewBuilder private func block(_ b: ReferenceDoc.Block) -> some View {
        switch b.type {
        case "heading":
            Text(b.text ?? "").font(b.level == 2 ? .title3.bold() : .headline)
        case "text":
            Text(b.text ?? "")
        case "list":
            VStack(alignment: .leading, spacing: 4) {
                ForEach(b.items ?? [], id: \.self) { Text("• \($0)") }
            }
        case "callout":
            Text(b.text ?? "")
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(calloutColor(b.tone).opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                .overlay(alignment: .leading) { Rectangle().fill(calloutColor(b.tone)).frame(width: 4) }
        case "table":
            ScrollView(.horizontal, showsIndicators: false) {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                    if let cols = b.columns {
                        GridRow { ForEach(cols, id: \.self) { Text($0).bold() } }
                    }
                    ForEach(Array((b.rows ?? []).enumerated()), id: \.offset) { _, row in
                        GridRow { ForEach(row, id: \.self) { Text($0) } }
                    }
                }
            }
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

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(proc.purpose).foregroundStyle(.secondary)
            Text(proc.outputType.uppercased() + (proc.meta.flags?.contains("stub") == true ? " · STUB" : ""))
                .font(.caption).foregroundStyle(.secondary)
            if let prompt = proc.entryPrompt { Text(prompt).font(.headline) }

            if isTree {
                ProcedureWalker(nodes: proc.nodes ?? [])
            } else {
                ForEach(proc.nodes ?? []) { node in
                    VStack(alignment: .leading, spacing: 4) {
                        if let p = node.prompt { Text(p).bold() }
                        if let b = node.body { Text(b).foregroundStyle(node.type == "warning" ? .red : .primary) }
                    }
                    .padding(.vertical, 4)
                }
            }

            if let checklist = proc.checklist, !checklist.isEmpty {
                Text("Checklist").font(.headline)
                ForEach(checklist, id: \.self) { Text("☐ \($0)") }
            }
            if let tmpl = proc.noteTemplate {
                Text("Procedure note template").font(.headline)
                Text(tmpl).font(.footnote.monospaced())
                    .padding(10).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            if let x = proc.crossLinks, !x.isEmpty {
                Text("Orchestrates: \(x.joined(separator: ", "))").font(.footnote).foregroundStyle(.secondary)
            }
            BuildNote(text: proc.buildNote)
        }
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
                    .font(.caption2).foregroundStyle(.secondary)
            }
            if let node = current {
                if let p = node.prompt { Text(p).font(.headline) }
                if let b = node.body {
                    Text(b)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background((node.type == "warning" ? Color.red : Color.green).opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                        .overlay(alignment: .leading) { Rectangle().fill(node.type == "warning" ? Color.red : Color.green).frame(width: 3) }
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
                    Text("End of this branch.").font(.footnote).foregroundStyle(.secondary)
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
            Text(tool.purpose).foregroundStyle(.secondary)
            if let age = tool.ageRange { Text(age).font(.caption).foregroundStyle(.secondary) }
            if let embedded = tool.embeddedCalculator {
                CalculatorView(calc: embedded, route: route)
            } else if let src = tool.sourceOfTruth, !src.isEmpty {
                Text("Defers to: \(src.joined(separator: ", "))").font(.footnote).foregroundStyle(.secondary)
            }
            if let body = tool.body, !body.isEmpty {
                BlockList(blocks: body)
            }
            BuildNote(text: tool.buildNote)
        }
    }
}

// MARK: - Anesthesia drug card (AnesCalc-origin)

struct AnesthesiaDrugCardBody: View {
    let card: AnesthesiaDrugCard
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(card.tallManLetters ?? card.meta.title).font(.headline)
                if let b = card.brandName { Text("· \(b)").foregroundStyle(.secondary) }
            }
            Text(card.drugClassLabel).font(.caption).foregroundStyle(.secondary)
            Text(card.mechanism).foregroundStyle(.secondary)

            HStack(spacing: 20) {
                labeled("Onset", card.onset)
                labeled("Duration", card.duration)
            }
            if let r = card.reversal { labeled("Reversal", r) }

            group("Dosing") {
                Text(card.dosing).font(.footnote.monospaced())
                    .padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
            }
            group("Cautions") { bullets(card.cautions) }
            group("Pearls") { bullets(card.pearls) }
        }
    }

    private func labeled(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased()).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.callout)
        }
    }
    @ViewBuilder private func group<C: View>(_ title: String, @ViewBuilder _ content: () -> C) -> some View {
        Text(title).font(.headline).padding(.top, 4)
        content()
    }
    private func bullets(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items, id: \.self) { Text("• \($0)").font(.callout) }
        }
    }
}

struct BuildNote: View {
    let text: String?
    var body: some View {
        if let text {
            DisclosureGroup("Build note") {
                Text(text).font(.footnote).foregroundStyle(.secondary)
            }
            .font(.footnote)
        }
    }
}
