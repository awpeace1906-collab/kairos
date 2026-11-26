import PDFKit
import PhotosUI
import SwiftUI
import UniformTypeIdentifiers
import TraumaCore

/// Photo / PDF import (Phase 1). Sources (camera, photo library, Files: images
/// and PDFs, combinable) → PDF page choice → on-device recognition → details
/// and tiers → one-line-at-a-time review with the source zoomed to the line →
/// kinds and auto-rules (templates only, user-typed parameters) → save gate.
/// The draft autosaves. Nothing leaves the device.
struct PhotoImportFlow: View {
    @ObservedObject var store: LocalProtocolStore
    let done: () -> Void

    enum Step: Int { case sources, pages, details, review, rules, save }

    @State private var draft = ImportDraft()
    @State private var step: Step = .sources
    @State private var images: [String: UIImage] = [:]          // "s-p" → page/photo image
    @State private var pdfs: [Int: PDFDocument] = [:]           // sourceIndex → document
    @State private var pdfSelection: [Int: Set<Int>] = [:]      // sourceIndex → selected pages
    @State private var pendingPhotos: [PhotosPickerItem] = []
    @State private var showCamera = false
    @State private var showFiles = false
    @State private var lockedPDF: URL?
    @State private var password = ""
    @State private var busy = false
    @State private var message: String?
    @State private var reviewIndex = 0

    var body: some View {
        Group {
            switch step {
            case .sources: sourcesStep
            case .pages: pagesStep
            case .details: detailsStep
            case .review: reviewStep
            case .rules: rulesStep
            case .save: saveStep
            }
        }
        .navigationTitle("Import protocol")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) { Button("Close") { persist(); done() } }
        }
        .overlay { if busy { ProgressView("Reading text on this device…").padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) } }
        .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) { Button("OK", role: .cancel) {} }
        .onAppear(perform: resume)
        .onChange(of: draft) { _ in persist() }
    }

    // MARK: - Persistence

    private func key(_ s: Int, _ p: Int?) -> String { "\(s)-\(p ?? 0)" }
    private func persist() { var d = draft; d.step = step.rawValue; store.saveDraft(d) }
    private func resume() {
        guard let d = store.loadDraft(), !d.lines.isEmpty || !d.sourceFiles.isEmpty else { return }
        draft = d
        step = Step(rawValue: d.step) ?? .details
        for l in d.lines where images[key(l.sourceIndex, l.page)] == nil {
            let url = store.draftSourcesDir.appendingPathComponent("page-\(key(l.sourceIndex, l.page)).png")
            images[key(l.sourceIndex, l.page)] = UIImage(contentsOfFile: url.path)
        }
    }

    private func storeSource(_ data: Data, name: String) -> URL? {
        let url = store.draftSourcesDir.appendingPathComponent("\(draft.sourceFiles.count + 1)-\(name)")
        do { try store.write(data, to: url); draft.sourceFiles.append(url.lastPathComponent); return url } catch { message = error.localizedDescription; return nil }
    }

    // MARK: - Step 1: sources

    private var sourcesStep: some View {
        List {
            Section {
                Button { showCamera = true } label: { Label("Take a photo", systemImage: "camera") }
                    .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                PhotosPicker(selection: $pendingPhotos, maxSelectionCount: 10, matching: .images) {
                    Label("Choose from photos", systemImage: "photo.on.rectangle")
                }
                Button { showFiles = true } label: { Label("Choose a file (image or PDF)", systemImage: "folder") }
            } footer: {
                Text("Combine several sources into one card, e.g. front and back photos or two PDF pages. Text is read on this device; nothing is uploaded.")
            }
            if !draft.sourceFiles.isEmpty {
                Section("Added") { ForEach(draft.sourceFiles, id: \.self) { Text($0).font(Theme.mono(12)) } }
                Section {
                    Toggle("Keep the source files with the profile", isOn: $draft.keepSources)
                    Button("Next") { step = pdfs.isEmpty ? .details : .pages; if pdfs.isEmpty { Task { await recognizeAll() } } }
                        .buttonStyle(.borderedProminent).tint(Theme.accent)
                        .accessibilityIdentifier("import-sources-next")
                }
            }
        }
        .onChange(of: pendingPhotos) { items in
            Task {
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) { _ = storeSource(data, name: "photo.jpg") }
                }
                pendingPhotos = []
            }
        }
        .sheet(isPresented: $showCamera) {
            CameraPicker { img in
                if let data = img.jpegData(compressionQuality: 0.95) { _ = storeSource(data, name: "camera.jpg") }
            }
            .ignoresSafeArea()
        }
        .fileImporter(isPresented: $showFiles, allowedContentTypes: [.image, .pdf], allowsMultipleSelection: true) { result in
            guard case .success(let urls) = result else { return }
            for u in urls { addFile(u) }
        }
        .alert("Password-protected PDF", isPresented: Binding(get: { lockedPDF != nil }, set: { if !$0 { lockedPDF = nil } })) {
            SecureField("Password", text: $password)
            Button("Open") { if let u = lockedPDF { openPDF(u, password: password) }; password = "" }
            Button("Cancel", role: .cancel) { password = "" }
        }
    }

    private func addFile(_ u: URL) {
        let scoped = u.startAccessingSecurityScopedResource()
        defer { if scoped { u.stopAccessingSecurityScopedResource() } }
        guard let data = try? Data(contentsOf: u), let local = storeSource(data, name: u.lastPathComponent) else { message = "That file couldn't be read."; return }
        if UTType(filenameExtension: u.pathExtension)?.conforms(to: .pdf) == true { openPDF(local, password: nil) }
    }

    private func openPDF(_ url: URL, password: String?) {
        do {
            let doc = try ImportPipeline.openPDF(url, password: password)
            let idx = draft.sourceFiles.firstIndex(of: url.lastPathComponent) ?? (draft.sourceFiles.count - 1)
            pdfs[idx] = doc
            pdfSelection[idx] = Set(0..<doc.pageCount) // default: all pages
        } catch ImportPipeline.ImportError.locked {
            if password == nil { lockedPDF = url } else { message = ImportPipeline.ImportError.locked.errorDescription }
        } catch { message = error.localizedDescription }
    }

    // MARK: - Step 2: PDF pages

    private var pagesStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(pdfs.keys.sorted(), id: \.self) { s in
                    Text(draft.sourceFiles[safe: s] ?? "PDF").font(Theme.mono(12))
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 10) {
                        ForEach(0..<(pdfs[s]?.pageCount ?? 0), id: \.self) { p in
                            let on = pdfSelection[s]?.contains(p) ?? false
                            Button {
                                if on { pdfSelection[s]?.remove(p) } else { pdfSelection[s, default: []].insert(p) }
                            } label: {
                                VStack {
                                    if let page = pdfs[s]?.page(at: p) { Image(uiImage: ImportPipeline.thumbnail(page)).resizable().scaledToFit().frame(height: 110) }
                                    Label("Page \(p + 1)", systemImage: on ? "checkmark.circle.fill" : "circle").font(Theme.caption)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Button("Read the selected pages") { step = .details; Task { await recognizeAll() } }
                    .buttonStyle(.borderedProminent).tint(Theme.accent)
            }
            .padding()
        }
    }

    // MARK: - Recognition

    private func recognizeAll() async {
        busy = true
        defer { busy = false }
        var results: [ImportPipeline.PageResult] = []
        do {
            for (s, name) in draft.sourceFiles.enumerated() {
                let url = store.draftSourcesDir.appendingPathComponent(name)
                if let doc = pdfs[s] {
                    for p in (pdfSelection[s] ?? []).sorted() {
                        guard let page = doc.page(at: p) else { continue }
                        results.append(try await ImportPipeline.extract(page: page, index: p, sourceIndex: s))
                    }
                } else if let img = UIImage(contentsOfFile: url.path) {
                    results.append(try await ImportPipeline.recognize(image: img, sourceIndex: s))
                }
            }
        } catch { message = error.localizedDescription; return }
        var lines: [ImportDraft.ReviewLine] = []
        for r in results {
            images[key(r.sourceIndex, r.page)] = r.image
            if let png = r.image.pngData() {
                try? store.write(png, to: store.draftSourcesDir.appendingPathComponent("page-\(key(r.sourceIndex, r.page)).png"))
            }
            draft.pathLog.append("source \(r.sourceIndex + 1)\(r.page.map { " page \($0 + 1)" } ?? ""): \(r.path.rawValue)")
            for (i, l) in r.lines.enumerated() {
                lines.append(.init(id: "s\(r.sourceIndex + 1)p\((r.page ?? 0) + 1)l\(i + 1)", text: l.text, sourceIndex: l.sourceIndex,
                                   page: l.page, box: l.box, path: l.path))
            }
        }
        draft.lines = lines
        if draft.tiers.isEmpty { draft.tiers = suggestedTiers(lines) }
    }

    /// Short all-caps lines are offered as tier headers; the user confirms or edits.
    private func suggestedTiers(_ lines: [ImportDraft.ReviewLine]) -> [ImportDraft.Tier] {
        let candidates = lines.filter { l in
            let t = l.text.trimmingCharacters(in: .whitespaces)
            return !t.isEmpty && t == t.uppercased() && t.split(separator: " ").count <= 2 && t.rangeOfCharacter(from: .letters) != nil
                && t.rangeOfCharacter(from: .decimalDigits) == nil && l.box.minY < 0.2
        }
        var seen = Set<String>()
        let uniq = candidates.filter { seen.insert($0.text.lowercased()).inserted }.prefix(6)
        return uniq.enumerated().map { i, l in
            .init(id: l.text.lowercased().replacingOccurrences(of: "[^a-z0-9]+", with: "_", options: .regularExpression),
                  label: l.text, color: "#888888", rank: uniq.count - i)
        }
    }

    // MARK: - Step 3: details, tiers, vitals

    private var detailsStep: some View {
        Form {
            Section("Card") {
                TextField("Institution", text: $draft.institution)
                TextField("Title", text: $draft.title)
                TextField("Revision date (YYYY-MM-DD)", text: $draft.revisionDate).keyboardType(.numbersAndPunctuation)
                TextField("Banner text (optional)", text: $draft.bannerText, axis: .vertical)
            }
            Section {
                ForEach($draft.tiers) { $t in
                    HStack {
                        TextField("Label", text: $t.label)
                        ColorPicker("", selection: Binding(get: { Color(hex: t.color) }, set: { t.color = $0.hexString }))
                            .labelsHidden().frame(width: 40)
                        Stepper("Rank \(t.rank)", value: $t.rank, in: 1...20).fixedSize()
                    }
                }
                .onDelete { draft.tiers.remove(atOffsets: $0) }
                Button("Add tier") {
                    let n = draft.tiers.count + 1
                    draft.tiers.append(.init(id: "tier_\(n)", label: "", color: "#888888", rank: n))
                }
            } header: { Text("Tiers") } footer: {
                Text("Higher rank wins when several tiers are met. Suggestions come from the card's header lines; confirm or edit them.")
            }
            Section {
                ForEach($draft.vitals) { $v in
                    VStack(alignment: .leading) {
                        HStack { Text(v.id).font(Theme.mono(12)); TextField("Label", text: $v.label); TextField("Unit", text: $v.unit) }
                        HStack {
                            TextField("Min", value: $v.min, format: .number).keyboardType(.decimalPad)
                            TextField("Max", value: $v.max, format: .number).keyboardType(.decimalPad)
                        }
                    }
                }
                .onDelete { draft.vitals.remove(atOffsets: $0) }
            } header: { Text("Vitals for auto-rules") } footer: {
                Text("Added when you attach an auto-rule that needs them. Enter each label, unit and range yourself.")
            }
            if !draft.pathLog.isEmpty {
                Section("How each page was read") { ForEach(draft.pathLog, id: \.self) { Text($0).font(Theme.mono(11)) } }
            }
            Button("Review lines") { reviewIndex = 0; step = .review }
                .disabled(draft.lines.isEmpty || draft.tiers.isEmpty)
                .accessibilityIdentifier("import-review-start")
        }
    }

    // MARK: - Step 4: line review (one at a time)

    private static let roles = ["criterion", "tier_header", "group_header", "team_response", "response_time", "note", "metadata", "ignore"]

    private var reviewStep: some View {
        let i = min(reviewIndex, max(draft.lines.count - 1, 0))
        return Group {
            if draft.lines.indices.contains(i) {
                let line = draft.lines[i]
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Line \(i + 1) of \(draft.lines.count) · \(line.path.rawValue)").font(Theme.mono(11)).foregroundStyle(.secondary)
                        if let img = images[key(line.sourceIndex, line.page)]?.crop(normalized: line.box) {
                            Image(uiImage: img).resizable().scaledToFit().frame(maxHeight: 140)
                                .border(Color(.separator))
                        }
                        TextField("Text", text: $draft.lines[i].text, axis: .vertical).font(Theme.callout)
                            .padding(8).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 8))
                        Picker("Role", selection: Binding(get: { draft.lines[i].role ?? "" }, set: { draft.lines[i].role = $0.isEmpty ? nil : $0 })) {
                            Text("Choose…").tag("")
                            ForEach(Self.roles, id: \.self) { Text($0.replacingOccurrences(of: "_", with: " ")).tag($0) }
                        }
                        Picker("Tier", selection: Binding(get: { draft.lines[i].tier ?? "" }, set: { draft.lines[i].tier = $0.isEmpty ? nil : $0 })) {
                            Text("None").tag("")
                            ForEach(draft.tiers) { Text($0.label).tag($0.id) }
                        }
                        TextField("Group (optional)", text: Binding(get: { draft.lines[i].group ?? "" }, set: { draft.lines[i].group = $0.isEmpty ? nil : $0 }))
                        HStack {
                            Button("Merge with next") { draft.merge(i) }.disabled(i + 1 >= draft.lines.count)
                            Button("Split at line breaks") { draft.split(i) }
                        }
                        .buttonStyle(.bordered)
                        Toggle("Confirmed: matches the card", isOn: $draft.lines[i].confirmed)
                            .accessibilityIdentifier("review-confirm")
                        if needsDoubleCheck(line.text) && draft.lines[i].role != "ignore" {
                            VStack(alignment: .leading, spacing: 6) {
                                highlighted(line.text).font(Theme.callout)
                                Toggle("Double-checked every number and symbol", isOn: $draft.lines[i].doubleChecked)
                                    .disabled(!draft.lines[i].confirmed)
                                    .accessibilityIdentifier("review-double-check")
                            }
                            .modifier(BandStyle(severity: "moderate"))
                        }
                        HStack {
                            Button("Back") { reviewIndex = max(0, i - 1) }.disabled(i == 0)
                            Spacer()
                            if i + 1 < draft.lines.count { Button("Next line") { reviewIndex = i + 1 }.buttonStyle(.borderedProminent).tint(Theme.accent) }
                            else { Button("Kinds and rules") { step = .rules }.buttonStyle(.borderedProminent).tint(Theme.accent) }
                        }
                    }
                    .padding()
                }
            } else {
                Text("No lines were found. Go back and add another source.").padding()
            }
        }
    }

    /// Digits and comparison symbols highlighted for the double check.
    private func highlighted(_ s: String) -> Text {
        s.reduce(Text("")) { acc, ch in
            let isRisky = "0123456789<>≤≥=%".contains(ch)
            return acc + (isRisky ? Text(String(ch)).bold().foregroundColor(Theme.severityColor("high")) : Text(String(ch)))
        }
    }

    // MARK: - Step 5: kinds and auto-rules

    private var templateList: [JSONValue] { store.templates["templates"]?.array ?? [] }

    private var rulesStep: some View {
        Form {
            ForEach(draft.lines.indices.filter { draft.lines[$0].role == "criterion" }, id: \.self) { i in
                Section {
                    Text(draft.lines[i].text).font(Theme.callout)
                    Picker("Kind", selection: Binding(get: { draft.lines[i].kind ?? "" }, set: { draft.lines[i].kind = $0.isEmpty ? nil : $0 })) {
                        Text("Choose…").tag("")
                        ForEach(["criterion", "discretion", "compound", "advisory"], id: \.self) { Text($0).tag($0) }
                    }
                    switch draft.lines[i].kind {
                    case "criterion":
                        ruleEditor(Binding(get: { draft.lines[i].auto }, set: { draft.lines[i].auto = $0 }), title: "Auto-rule (optional)")
                    case "compound":
                        TextField("Base text", text: Binding(get: { draft.lines[i].compoundBaseText ?? "" }, set: { draft.lines[i].compoundBaseText = $0 }))
                        Picker("Also needs any criterion of", selection: Binding(get: { draft.lines[i].compoundRequiresTier ?? "" }, set: { draft.lines[i].compoundRequiresTier = $0 })) {
                            Text("Choose…").tag(""); ForEach(draft.tiers) { Text($0.label).tag($0.id) }
                        }
                        TextField("Hint when not met", text: Binding(get: { draft.lines[i].compoundHint ?? "" }, set: { draft.lines[i].compoundHint = $0 }))
                        ruleEditor(Binding(get: { draft.lines[i].compoundBase }, set: { draft.lines[i].compoundBase = $0 }), title: "Base auto-rule (optional)")
                    case "advisory":
                        Picker("Show when the result is", selection: Binding(get: { draft.lines[i].advisoryTier ?? "" }, set: { draft.lines[i].advisoryTier = $0 })) {
                            Text("Choose…").tag(""); ForEach(draft.tiers) { Text($0.label).tag($0.id) }
                        }
                    default: EmptyView()
                    }
                }
            }
            Button("Review and save") { step = .save }.buttonStyle(.borderedProminent).tint(Theme.accent)
        }
    }

    /// Template picker + user-typed parameters, with the filled-in `plain` sentence.
    @ViewBuilder private func ruleEditor(_ ref: Binding<ImportDraft.TemplateRef?>, title: String) -> some View {
        Picker(title, selection: Binding(get: { ref.wrappedValue?.id ?? "" }, set: { id in
            ref.wrappedValue = id.isEmpty ? nil : ImportDraft.TemplateRef(id: id, params: [:])
            if let t = templateList.first(where: { $0["id"]?.string == id }) { addNeededVitals(t) }
        })) {
            Text("None").tag("")
            ForEach(templateList.compactMap { $0["id"]?.string }, id: \.self) { id in
                Text(templateList.first { $0["id"]?.string == id }?["label"]?.string ?? id).tag(id)
            }
        }
        if let r = ref.wrappedValue, let t = templateList.first(where: { $0["id"]?.string == r.id }) {
            ForEach(t["params"]?.array?.compactMap { $0["id"]?.string } ?? [], id: \.self) { pid in
                let type = t["params"]?.array?.first { $0["id"]?.string == pid }?["type"]?.string
                if type == "vital_id" {
                    Picker(pid, selection: Binding(get: { r.params[pid]?.string ?? "" }, set: { ref.wrappedValue?.params[pid] = .string($0) })) {
                        Text("Choose…").tag("")
                        ForEach(draft.vitals) { Text($0.label.isEmpty ? $0.id : $0.label).tag($0.id) }
                    }
                } else {
                    TextField(pid, text: Binding(get: { r.params[pid]?.number.map(jsNumberString) ?? "" },
                                                 set: { ref.wrappedValue?.params[pid] = Double($0.replacingOccurrences(of: ",", with: ".")).map { .number($0) } }))
                        .keyboardType(.decimalPad)
                }
            }
            Text(fillPlain(t, params: r.params, vitalLabel: { id in draft.vitals.first { $0.id == id }?.label ?? id }))
                .font(Theme.mono(13)).foregroundStyle(Theme.accent)
        }
    }

    /// Vital ids a template refers to by name get a vital entry; the user types its label, unit and range.
    private func addNeededVitals(_ template: JSONValue) {
        var ids: [String] = []
        func walk(_ n: JSONValue) {
            switch n {
            case .object(let o): if let v = o["var"]?.string, !v.hasPrefix("{") { ids.append(v) }; o.values.forEach(walk)
            case .array(let a): a.forEach(walk)
            default: break
            }
        }
        walk(template["rule"] ?? .null)
        for id in ids where !draft.vitals.contains(where: { $0.id == id }) {
            draft.vitals.append(.init(id: id, label: "", unit: "", min: 0, max: 0, decimals: 0))
        }
    }

    // MARK: - Step 6: save gate

    private var saveStep: some View {
        let gate = draft.saveGate
        return Form {
            Section("Save check") {
                if gate.ok { Label("Every line is assigned, confirmed and double-checked.", systemImage: "checkmark.seal") }
                ForEach(Array(gate.blocking.enumerated()), id: \.offset) { _, b in
                    Button("\(b.code.replacingOccurrences(of: "_", with: " "))\(b.line.map { " — \($0)" } ?? "")") {
                        if let id = b.line, let idx = draft.lines.firstIndex(where: { $0.id == id }) { reviewIndex = idx; step = .review }
                    }
                }
            }
            Button("Save to library") { save() }
                .disabled(!gate.ok)
                .buttonStyle(.borderedProminent).tint(Theme.accent)
                .accessibilityIdentifier("import-save")
        }
    }

    private func save() {
        do {
            let viaPDF = !pdfs.isEmpty
            let profile = try draft.buildProfile(templates: store.templates, createdVia: viaPDF ? "pdf_import" : "photo_import")
            let keep = draft.keepSources ? draft.sourceFiles.map { store.draftSourcesDir.appendingPathComponent($0) } : []
            switch try store.add(profile, keepSources: keep) {
            case .success:
                store.discardDraft()
                done()
            case .failure(let f):
                message = "The profile has problems: " + f.issues.map { "\($0.code) (\($0.at))" }.joined(separator: ", ")
            }
        } catch { message = error.localizedDescription }
    }
}

extension Array {
    subscript(safe i: Int) -> Element? { indices.contains(i) ? self[i] : nil }
}

extension Color {
    var hexString: String {
        let c = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        c.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}

/// Camera capture (UIImagePickerController); the photo stays on the device.
struct CameraPicker: UIViewControllerRepresentable {
    let onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }
    func updateUIViewController(_ vc: UIImagePickerController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ p: CameraPicker) { parent = p }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.onImage(img) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
