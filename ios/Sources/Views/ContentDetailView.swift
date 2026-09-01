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
        case pedsTool(PedsTool)

        var meta: RecordMeta {
            switch self {
            case .calculator(let m): return m.meta
            case .reference(let m):  return m.meta
            case .procedure(let m):  return m.meta
            case .drugCard(let m):   return m.meta
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
            if let s = doc.meta.sources, !s.isEmpty {}
            if let summary = doc.summary {
                Text(summary).foregroundStyle(.secondary)
            }
            ForEach(Array(doc.body.enumerated()), id: \.offset) { _, block in
                blockView(block)
            }
            BuildNote(text: doc.buildNote)
        }
    }

    @ViewBuilder private func blockView(_ b: ReferenceDoc.Block) -> some View {
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
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(proc.purpose).foregroundStyle(.secondary)
            Text(proc.outputType.uppercased() + (proc.meta.flags?.contains("stub") == true ? " · STUB" : ""))
                .font(.caption).foregroundStyle(.secondary)
            if let prompt = proc.entryPrompt { Text(prompt).font(.headline) }
            ForEach(proc.nodes ?? []) { node in
                VStack(alignment: .leading, spacing: 4) {
                    if let p = node.prompt { Text(p).bold() }
                    if let b = node.body { Text(b) }
                    ForEach(node.choices ?? [], id: \.label) { c in
                        Text("→ \(c.label)").font(.callout).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
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
            BuildNote(text: proc.buildNote)
        }
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
            BuildNote(text: tool.buildNote)
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
