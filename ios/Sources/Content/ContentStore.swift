import Foundation

// The delivery state machine from Content_Update_Architecture_Spec.md, iOS side.
//
//   render from cache, always  ->  poll a lightweight manifest when online  ->
//   background-fetch only changed modules into Caches/  ->  swap silently.
//
// Bundled fallback: the whole content/ tree ships as a "Content" folder resource
// (see ios/project.yml), so a first launch with no connectivity still works.
// Mirrors web/src/lib/contentStore.js.

@MainActor
final class ContentStore: ObservableObject {

    /// Set to the CDN base that serves the versioned content/ tree to enable OTA updates.
    static let remoteBase: URL? = nil

    @Published private(set) var sections: [AppSection] = []
    @Published private(set) var searchIndex = SearchIndex(entries: [])
    @Published private(set) var weightZones: WeightZonesConfig?
    @Published private(set) var tiers: [TiersConfig.Tier] = []
    @Published private(set) var manifest: Manifest?
    @Published private(set) var lastUpdatedModules: [String] = []
    @Published private(set) var loadError: String?

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d   // CodingKeys are explicit; do NOT use .convertFromSnakeCase
    }()

    private var cachesDir: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KairosContent", isDirectory: true)
    }

    func load() {
        do {
            let s: SectionsConfig = try bundled("config/sections.json")
            let idx: SearchIndexFile = try bundled("search-index.json")
            let zones: WeightZonesConfig = try bundled("config/weight-zones.json")
            let t: TiersConfig = try bundled("config/tiers.json")
            let m: Manifest = try bundled("manifest.json")
            sections = s.sections.sorted { $0.order < $1.order }
            searchIndex = SearchIndex(entries: idx.entries)
            weightZones = zones
            tiers = t.tiers
            manifest = m
        } catch {
            loadError = "Bundled content failed to load: \(error)"
            print("[content] \(loadError!)")
        }
        Task { await checkForUpdates() }
    }

    func entry(forRoute route: String) -> SearchEntry? {
        searchIndex.entries.first { $0.route == route }
    }

    /// Loads a module by search-index route, decoding to the concrete type.
    func loadModuleData(forRoute route: String) throws -> (SearchEntry, Data) {
        guard let entry = entry(forRoute: route),
              let manifest,
              let key = manifest.modules.first(where: { $0.value.path.hasSuffix("/\(entry.itemID).json") })?.key
        else { throw ContentError.notFound(route) }
        let relPath = manifest.modules[key]!.path        // e.g. "modules/calculators/.../x.json"

        // OTA copy in Caches wins over the bundled baseline.
        let cached = cachesDir.appendingPathComponent(relPath)
        if let data = try? Data(contentsOf: cached) { return (entry, data) }
        return (entry, try bundledData(relPath))
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }

    // MARK: - bundled resources

    private func bundled<T: Decodable>(_ relPath: String) throws -> T {
        try decoder.decode(T.self, from: try bundledData(relPath))
    }

    private func bundledData(_ relPath: String) throws -> Data {
        // The folder reference is copied into the bundle under its on-disk name,
        // "content" (lowercase — the `name:` in project.yml only renames the Xcode
        // group, not the copied directory). Bundle.url(...) matching is
        // case-sensitive even on the simulator's case-insensitive filesystem.
        let file = (relPath as NSString).lastPathComponent
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension

        for prefix in ["content", "Content"] {
            let subdir = prefix + "/" + (relPath as NSString).deletingLastPathComponent
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                return try Data(contentsOf: url)
            }
            if let resURL = Bundle.main.resourceURL {
                let direct = resURL.appendingPathComponent(prefix + "/" + relPath)
                if FileManager.default.fileExists(atPath: direct.path) {
                    return try Data(contentsOf: direct)
                }
            }
        }
        // Last fallback: resources flattened into the bundle root.
        if let url = Bundle.main.url(forResource: name, withExtension: ext) {
            return try Data(contentsOf: url)
        }
        throw ContentError.missingResource("content/" + relPath)
    }

    // MARK: - OTA update check

    func checkForUpdates() async {
        guard let remoteBase = Self.remoteBase else { return }
        do {
            let (data, _) = try await URLSession.shared.data(from: remoteBase.appendingPathComponent("manifest.json"))
            let remote = try decoder.decode(Manifest.self, from: data)
            var cachedVersions = UserDefaults.standard.dictionary(forKey: "kairos.manifest.v1") as? [String: Int] ?? [:]
            try FileManager.default.createDirectory(at: cachesDir, withIntermediateDirectories: true)

            var changed: [String] = []
            for (key, m) in remote.modules where (cachedVersions[key] ?? 0) < m.contentVersion {
                let src = remoteBase.appendingPathComponent(m.path)
                let (moduleData, _) = try await URLSession.shared.data(from: src)
                let dest = cachesDir.appendingPathComponent(m.path)
                try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try moduleData.write(to: dest, options: .atomic)
                cachedVersions[key] = m.contentVersion
                changed.append(key)
            }
            if !changed.isEmpty {
                UserDefaults.standard.set(cachedVersions, forKey: "kairos.manifest.v1")
                manifest = remote
                lastUpdatedModules = changed
            }
        } catch {
            // Offline or the CDN is unreachable — we simply keep rendering from cache.
            print("[content] update check skipped: \(error)")
        }
    }
}

enum ContentError: Error, CustomStringConvertible {
    case notFound(String)
    case missingResource(String)
    var description: String {
        switch self {
        case .notFound(let r): return "no content at route \(r)"
        case .missingResource(let p): return "bundled resource missing: \(p)"
        }
    }
}
