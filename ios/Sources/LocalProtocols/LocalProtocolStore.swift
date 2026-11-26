import Foundation
import TraumaCore

/// On-device library of the user's local trauma-activation profiles (Local
/// Protocols). Nothing here ships in the app: every profile comes from the
/// user (photo/PDF/JSON import) and stays on the device.
///
/// Storage: Application Support/LocalProtocols/ in the app sandbox, written
/// with FileProtectionType.complete. The folder is excluded from backup
/// unless the user turns backup on in Settings (`backupKey`).
///   library.json            the ProfileLibrary (all facilities, all versions)
///   sources/<profile_id>/   source photos/PDFs, only if the user opted to keep them
///   draft.json              an unfinished photo/PDF import
@MainActor
final class LocalProtocolStore: ObservableObject {
    static let shared = LocalProtocolStore()
    static let backupKey = "kairos.localProtocols.iCloudBackup"

    @Published private(set) var library = ProfileLibrary()
    @Published private(set) var loadError: String?
    /// The bundled auto-rule templates (rule-templates.json). The only bundled kit file.
    let templates: JSONValue

    let root: URL

    init(root: URL? = nil) {
        let base = root ?? FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("LocalProtocols", isDirectory: true)
        self.root = base
        if let url = Bundle.main.url(forResource: "rule-templates", withExtension: "json"),
           let data = try? Data(contentsOf: url), let t = try? JSONValue.parse(data) {
            templates = t
        } else {
            templates = .object(["templates": .array([])])
        }
        load()
    }

    private var libraryURL: URL { root.appendingPathComponent("library.json") }
    var draftURL: URL { root.appendingPathComponent("draft.json") }
    func sourcesDir(_ profileId: String) -> URL { root.appendingPathComponent("sources/\(profileId)", isDirectory: true) }

    // MARK: - Persistence

    func load() {
        do {
            try prepareRoot()
            if FileManager.default.fileExists(atPath: libraryURL.path) {
                library = try JSONDecoder().decode(ProfileLibrary.self, from: Data(contentsOf: libraryURL))
            }
        } catch {
            loadError = "Local protocols could not be read: \(error.localizedDescription)"
        }
    }

    private func prepareRoot() throws {
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        try applyBackupSetting()
    }

    /// Exclude the whole folder from backup unless the user opted in.
    func applyBackupSetting() throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = !UserDefaults.standard.bool(forKey: Self.backupKey)
        var url = root
        try url.setResourceValues(values)
    }

    func write(_ data: Data, to url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                                                attributes: [.protectionKey: FileProtectionType.complete])
        try data.write(to: url, options: [.atomic, .completeFileProtection])
    }

    private func save() throws {
        let e = JSONEncoder(); e.outputFormatting = [.sortedKeys]
        try write(try e.encode(library), to: libraryURL)
    }

    // MARK: - Library operations (all via TraumaCore; nothing is overwritten)

    var groups: [InstitutionGroup] { listByInstitution(library) }

    func entry(_ id: String?) -> LibraryEntry? { library.entries.first { $0.profileId == id } }

    var defaultProfile: LibraryEntry? { entry(library.default_profile_id) ?? library.entries.first }

    /// Validates (after forcing personal_only) and adds. Returns the new id, or the validation issues.
    @discardableResult
    func add(_ profile: JSONValue, keepSources: [URL] = []) throws -> Result<String, ValidationFailure> {
        var p = profile.object ?? [:]
        p["distribution"] = .string("personal_only") // every profile is personal_only
        let forced = JSONValue.object(p)
        let issues = validateProfile(forced, templates: templates)
        guard issues.isEmpty else { return .failure(ValidationFailure(issues)) }
        let (lib, id) = addToLibrary(library, profile: forced, addedAt: ISO8601DateFormatter().string(from: Date()))
        for (i, src) in keepSources.enumerated() {
            let dest = sourcesDir(id).appendingPathComponent("\(i + 1)-\(src.lastPathComponent)")
            try write(try Data(contentsOf: src), to: dest)
        }
        library = lib
        try save()
        return .success(id)
    }

    func setDefault(_ id: String) throws {
        library.default_profile_id = id
        try save()
    }

    /// Renames every version of one facility (the group stays together).
    func renameInstitution(of id: String, to name: String) throws {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let group = groups.first(where: { $0.versions.contains { $0.profileId == id } }) else { return }
        let ids = Set(group.versions.map(\.profileId))
        library.entries = library.entries.map { e in
            guard ids.contains(e.profileId), var o = e.profile.object else { return e }
            o["institution"] = .string(trimmed)
            return LibraryEntry(profile: .object(o), added_at: e.added_at)
        }
        try save()
    }

    /// Delete is the only way anything is removed (the UI confirms first).
    func delete(_ id: String) throws {
        library = removeFromLibrary(library, profileId: id)
        try? FileManager.default.removeItem(at: sourcesDir(id))
        try save()
    }

    func sourceFiles(_ id: String) -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: sourcesDir(id), includingPropertiesForKeys: nil))?
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
    }

    func exportData(_ id: String) throws -> Data {
        guard let e = entry(id) else { throw CocoaError(.fileNoSuchFile) }
        return try e.profile.data(pretty: true)
    }

    /// Current/superseded status within the facility.
    func isCurrent(_ id: String) -> Bool { groups.contains { $0.currentProfileId == id } }
}
