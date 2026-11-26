import SwiftUI
import UniformTypeIdentifiers
import TraumaCore

/// Local Protocols root: the user's own trauma-activation profiles, grouped by
/// facility (all versions kept). Import from a JSON file or from photos/PDFs;
/// open a profile's bedside checklist. Nothing here ships with the app.
struct LocalProtocolsView: View {
    @StateObject private var store = LocalProtocolStore.shared
    @State private var importingJSON = false
    @State private var pendingImport: PendingImport?
    @State private var importError: String?
    @State private var showPhotoImport = false

    struct PendingImport: Identifiable {
        let id = UUID()
        let profile: JSONValue
        let issues: [ValidationIssue]
    }

    var body: some View {
        List {
            if let err = store.loadError { Text(err).foregroundStyle(Theme.severityColor("high")) }
            if let def = store.defaultProfile {
                Section {
                    NavigationLink {
                        TraumaChecklistView(store: store, profileId: def.profileId)
                    } label: {
                        let m = ProfileModel(raw: def.profile)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(m.title).font(Theme.semibold(16))
                            Text("\(m.institution) · \(m.revisionDate)").font(Theme.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("local-open-default")
                } header: { Text("Default").font(Theme.mono(11)).tracking(1).textCase(.uppercase) }
            }
            Section {
                if store.groups.isEmpty {
                    Text("No local protocols yet. Import your facility's trauma-activation card from a photo, a PDF or a JSON file. Profiles stay on this device.")
                        .font(Theme.callout).foregroundStyle(.secondary)
                }
                ForEach(store.groups, id: \.currentProfileId) { g in
                    NavigationLink {
                        FacilityVersionsView(store: store, institution: g.institution)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(g.institution).font(Theme.semibold(16))
                            Text(g.versions.count == 1 ? "1 version" : "\(g.versions.count) versions")
                                .font(Theme.caption).foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityIdentifier("local-facility-\(g.currentProfileId)")
                }
            } header: { Text("Facilities").font(Theme.mono(11)).tracking(1).textCase(.uppercase) }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Local Protocols")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button { showPhotoImport = true } label: { Label("From photo or PDF", systemImage: "doc.viewfinder") }
                    Button { importingJSON = true } label: { Label("From JSON file", systemImage: "doc.badge.plus") }
                } label: { Image(systemName: "plus") }
                .accessibilityLabel("Import a protocol")
                .accessibilityIdentifier("local-import")
            }
        }
        .fileImporter(isPresented: $importingJSON, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url): prepareJSON(url)
            case .failure(let e): importError = e.localizedDescription
            }
        }
        .sheet(item: $pendingImport) { p in
            JSONImportSummary(store: store, pending: p) { pendingImport = nil }
        }
        .sheet(isPresented: $showPhotoImport) {
            NavigationStack { PhotoImportFlow(store: store) { showPhotoImport = false } }
        }
        .alert("Import failed", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } })) {
            Button("OK", role: .cancel) {}
        } message: { Text(importError ?? "") }
    }

    private func prepareJSON(_ url: URL) {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            var p = try JSONValue.parse(Data(contentsOf: url)).object ?? [:]
            p["distribution"] = .string("personal_only") // imports are forced to personal_only
            let profile = JSONValue.object(p)
            pendingImport = PendingImport(profile: profile, issues: validateProfile(profile, templates: store.templates))
        } catch {
            importError = "That file isn't a readable profile (\(error.localizedDescription))."
        }
    }
}

/// JSON import: validation result and a summary (institution, revision date,
/// criteria per tier) the user confirms before the profile is added.
struct JSONImportSummary: View {
    @ObservedObject var store: LocalProtocolStore
    let pending: LocalProtocolsView.PendingImport
    let done: () -> Void
    @State private var error: String?

    var body: some View {
        let m = ProfileModel(raw: pending.profile)
        NavigationStack {
            List {
                Section("Profile") {
                    LabeledContent("Institution", value: m.institution)
                    LabeledContent("Title", value: m.title)
                    LabeledContent("Revision date", value: m.revisionDate)
                    if let b = m.bannerText { Text(b).font(Theme.footnote) }
                }
                Section("Criteria per tier") {
                    ForEach(m.tiers) { t in LabeledContent(t.label, value: "\(m.criteriaCount(tier: t.id))") }
                }
                if !pending.issues.isEmpty {
                    Section("Can't import: the profile has problems") {
                        ForEach(Array(pending.issues.enumerated()), id: \.offset) { _, i in
                            Text("\(i.code) — \(i.at)").font(Theme.mono(12))
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(Theme.severityColor("high")) }
            }
            .navigationTitle("Import protocol")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: done) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add to library") {
                        do {
                            if case .failure(let f) = try store.add(pending.profile) {
                                error = f.issues.map(\.code).joined(separator: ", ")
                            } else { done() }
                        } catch { self.error = error.localizedDescription }
                    }
                    .disabled(!pending.issues.isEmpty)
                    .accessibilityIdentifier("json-import-confirm")
                }
            }
        }
    }
}

/// One facility: every version, newest revision current, older ones superseded.
struct FacilityVersionsView: View {
    @ObservedObject var store: LocalProtocolStore
    let institution: String
    @State private var renaming: String?
    @State private var newName = ""
    @State private var confirmDelete: String?
    @State private var sourceViewing: String?

    private var group: InstitutionGroup? {
        store.groups.first { $0.institution.trimmingCharacters(in: .whitespaces).lowercased() == institution.trimmingCharacters(in: .whitespaces).lowercased() }
            ?? store.groups.first { g in g.versions.contains { v in store.entry(v.profileId).map { ProfileModel(raw: $0.profile).institution == institution } ?? false } }
    }

    var body: some View {
        List {
            if let group {
                ForEach(group.versions, id: \.profileId) { v in
                    let entry = store.entry(v.profileId)
                    let m = entry.map { ProfileModel(raw: $0.profile) }
                    NavigationLink {
                        TraumaChecklistView(store: store, profileId: v.profileId)
                    } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(m?.title ?? v.profileId).font(Theme.semibold(15))
                            HStack(spacing: 6) {
                                Text(v.sourceRevisionDate).font(Theme.mono(12))
                                Text(v.profileId == group.currentProfileId ? "current" : "superseded")
                                    .font(Theme.caption)
                                    .foregroundStyle(v.profileId == group.currentProfileId ? Theme.severityColor("low") : .secondary)
                                if store.library.default_profile_id == v.profileId {
                                    Text("default").font(Theme.caption).foregroundStyle(Theme.accent)
                                }
                            }
                        }
                    }
                    .accessibilityIdentifier("local-version-\(v.profileId)")
                    .contextMenu {
                        Button("Set as default") { try? store.setDefault(v.profileId) }
                        Button("Rename institution") { newName = m?.institution ?? ""; renaming = v.profileId }
                        if !store.sourceFiles(v.profileId).isEmpty { Button("View source") { sourceViewing = v.profileId } }
                        if let data = try? store.exportData(v.profileId) {
                            ShareLink(item: ProfileJSONFile(data: data, name: v.profileId), preview: SharePreview(m?.title ?? v.profileId)) {
                                Label("Export JSON", systemImage: "square.and.arrow.up")
                            }
                        }
                        Button("Delete", role: .destructive) { confirmDelete = v.profileId }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) { confirmDelete = v.profileId }
                        Button("Default") { try? store.setDefault(v.profileId) }.tint(Theme.accent)
                    }
                }
            }
        }
        .navigationTitle(institution)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Delete this version? This removes it from the device.",
                            isPresented: Binding(get: { confirmDelete != nil }, set: { if !$0 { confirmDelete = nil } }),
                            titleVisibility: .visible) {
            Button("Delete", role: .destructive) { if let id = confirmDelete { try? store.delete(id) } }
        }
        .alert("Rename institution", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Institution", text: $newName)
            Button("Rename") { if let id = renaming { try? store.renameInstitution(of: id, to: newName) } }
            Button("Cancel", role: .cancel) {}
        } message: { Text("Renames every version of this facility.") }
        .sheet(item: Binding(get: { sourceViewing.map { SourceID(id: $0) } }, set: { sourceViewing = $0?.id })) { s in
            NavigationStack { SourceFilesView(files: store.sourceFiles(s.id)) }
        }
    }

    struct SourceID: Identifiable { let id: String }
}

/// Profile JSON for export through the share sheet (in memory).
struct ProfileJSONFile: Transferable {
    let data: Data
    let name: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { $0.data }
            .suggestedFileName("trauma-activation-profile.json")
    }
}

/// The source photos/PDFs kept with a profile (only if the user opted in).
struct SourceFilesView: View {
    let files: [URL]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(files, id: \.self) { url in
                    if let img = UIImage(contentsOfFile: url.path) {
                        Image(uiImage: img).resizable().scaledToFit()
                    } else {
                        Label(url.lastPathComponent, systemImage: "doc").font(Theme.callout)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Source")
        .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}
