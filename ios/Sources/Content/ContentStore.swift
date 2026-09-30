import CryptoKit
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

    /// The static host that serves the versioned content/ tree (deploy.yml →
    /// GitHub Pages). The app renders from its bundled copy first, then polls
    /// this for modules whose content hash differs from the copy it shows (and
    /// whose version is not lower) and swaps them in — no App Store submission.
    /// Set to nil to pin to the bundled content only.
    static let remoteBase: URL? = URL(string: "https://awpeace1906-collab.github.io/kairos/content/")

    @Published private(set) var sections: [AppSection] = []
    @Published private(set) var searchIndex = SearchIndex(entries: [])
    @Published private(set) var sourcesIndex: SourcesIndexFile?
    @Published private(set) var careSettings: [SettingsConfig.CareSetting] = []
    /// Curated default pin ids + their config labels/blurbs (config/pinned.json).
    @Published private(set) var pinnedConfig: [PinnedConfig.Entry] = []
    @Published private(set) var weightZones: WeightZonesConfig?
    @Published private(set) var tiers: [TiersConfig.Tier] = []
    @Published private(set) var manifest: Manifest?
    /// The manifest shipped inside this build — the baseline OTA compares against.
    private var bundledManifest: Manifest?
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

    // OTA bookkeeping. `otaHashes` / `otaVersions` record every module copy
    // downloaded into Caches/ under the CURRENT bundle; a cached file with no
    // record is ignored. `bundleKey` fingerprints the bundled manifest so a new
    // install (Xcode, TestFlight, App Store) starts clean from its own bundle
    // instead of from copies downloaded under an older one.
    private static let otaHashesKey = "kairos.ota.hashes.v2"
    private static let otaVersionsKey = "kairos.ota.versions.v2"
    private static let bundleKey = "kairos.ota.bundle.v2"
    private static let legacyVersionsKey = "kairos.manifest.v1"
    private var otaHashes: [String: String] {
        get { UserDefaults.standard.dictionary(forKey: Self.otaHashesKey) as? [String: String] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: Self.otaHashesKey) }
    }
    private var otaVersions: [String: Int] {
        get { UserDefaults.standard.dictionary(forKey: Self.otaVersionsKey) as? [String: Int] ?? [:] }
        set { UserDefaults.standard.set(newValue, forKey: Self.otaVersionsKey) }
    }

    /// SHA-256 of the bundled manifest.json bytes. Changes whenever the bundled
    /// content does, so it identifies "which content this build shipped with".
    nonisolated static func bundleFingerprint(_ manifestData: Data) -> String {
        SHA256.hash(data: manifestData).map { String(format: "%02x", $0) }.joined()
    }

    /// Download a module when the published copy differs from the one the app
    /// shows (by content hash, so an edit that skipped a content_version bump
    /// still arrives), but never when the published copy has a LOWER version —
    /// that protects a build whose bundle is ahead of the CDN (unpushed content).
    nonisolated static func shouldDownload(remoteHash: String, remoteVersion: Int,
                                           currentHash: String?, currentVersion: Int) -> Bool {
        remoteHash != currentHash && remoteVersion >= currentVersion
    }

    /// A different bundle than last launch means a new install: drop every OTA
    /// copy and record so the new bundle is the baseline. Before this, a copy
    /// cached under an older build won over the newer bundle whenever the two
    /// shared a content_version, and could show stale text indefinitely.
    private func resetOTAIfBundleChanged(_ manifestData: Data) {
        let fp = Self.bundleFingerprint(manifestData)
        let d = UserDefaults.standard
        guard d.string(forKey: Self.bundleKey) != fp else { return }
        try? FileManager.default.removeItem(at: cachesDir)
        d.removeObject(forKey: Self.otaHashesKey)
        d.removeObject(forKey: Self.otaVersionsKey)
        d.removeObject(forKey: Self.legacyVersionsKey)
        d.set(fp, forKey: Self.bundleKey)
    }

    func load() {
        // Must run before anything reads Caches/ (cachedOrBundled below).
        if let data = try? bundledData("manifest.json") { resetOTAIfBundleChanged(data) }
        do {
            // A prior successful checkForUpdates() run persists a fresher copy of
            // these two into Caches/ — prefer that over the build-time bundle so a
            // relaunch shows the last-known-good synced state immediately, before
            // this session's own checkForUpdates() call below even completes.
            let s: SectionsConfig = try cachedOrBundled("config/sections.json")
            let idx: SearchIndexFile = try cachedOrBundled("search-index.json")
            let zones: WeightZonesConfig = try bundled("config/weight-zones.json")
            let t: TiersConfig = try bundled("config/tiers.json")
            let bundledM: Manifest = try bundled("manifest.json")
            // The last synced manifest (if any, from under this bundle) knows the
            // paths of modules that exist only OTA; the bundled one does not.
            let m: Manifest = try cachedOrBundled("manifest.json")
            sections = s.sections.sorted { $0.order < $1.order }
            searchIndex = SearchIndex(entries: idx.entries)
            weightZones = zones
            tiers = t.tiers
            manifest = m
            bundledManifest = bundledM
        } catch {
            loadError = "Bundled content failed to load: \(error)"
            print("[content] \(loadError!)")
        }
        // Non-fatal: an older bundled content/ tree (pre-2026-09-04) won't have this
        // file yet. The Sources page just shows nothing rather than failing the app.
        sourcesIndex = try? bundled("sources-index.json")
        careSettings = ((try? bundled("config/settings.json")) as SettingsConfig?)?.settings.sorted { $0.order < $1.order } ?? []
        pinnedConfig = ((try? bundled("config/pinned.json")) as PinnedConfig?)?.pinned ?? []
        Task { await checkForUpdates() }
    }

    func entry(forRoute route: String) -> SearchEntry? {
        searchIndex.entries.first { $0.route == route }
    }

    var curatedPinIds: [String] { pinnedConfig.map(\.id) }

    /// Resolve an ordered id list → home-screen cards. Curated entries keep their
    /// config label/blurb; user-added ones fall back to the module title / category.
    func resolvePins(_ ids: [String]) -> [PinnedShortcut] {
        let byID = Dictionary(uniqueKeysWithValues: searchIndex.entries.map { ($0.itemID, $0) })
        let curated = Dictionary(uniqueKeysWithValues: pinnedConfig.map { ($0.id, $0) })
        return ids.compactMap { id in
            guard let e = byID[id] else { return nil }
            let c = curated[id]
            return PinnedShortcut(label: c?.label ?? e.title, blurb: c?.blurb ?? e.category, route: e.route)
        }
    }

    /// Loads a module by search-index route, decoding to the concrete type.
    func loadModuleData(forRoute route: String) throws -> (SearchEntry, Data) {
        guard let entry = entry(forRoute: route),
              let manifest,
              let key = manifest.modules.first(where: { $0.value.path.hasSuffix("/\(entry.itemID).json") })?.key
        else { throw ContentError.notFound(route) }
        let relPath = manifest.modules[key]!.path        // e.g. "modules/calculators/.../x.json"

        // An OTA copy downloaded under this bundle wins; anything else in
        // Caches/ (no record) is ignored in favor of the bundled baseline.
        if otaHashes[key] != nil, let data = try? Data(contentsOf: cachesDir.appendingPathComponent(relPath)) {
            return (entry, data)
        }
        return (entry, try bundledData(relPath))
    }

    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        try decoder.decode(T.self, from: data)
    }

    // MARK: - bundled resources

    private func bundled<T: Decodable>(_ relPath: String) throws -> T {
        try decoder.decode(T.self, from: try bundledData(relPath))
    }

    /// A prior checkForUpdates() may have persisted a fresher copy of `relPath`
    /// into Caches/ — prefer it, falling back to the build-time bundle. Used for
    /// the two "structural" files (search-index.json, config/sections.json) that
    /// determine what content is even discoverable, as opposed to individual
    /// module payloads (which loadModuleData already handles this way).
    private func cachedOrBundled<T: Decodable>(_ relPath: String) throws -> T {
        let cached = cachesDir.appendingPathComponent(relPath)
        if let data = try? Data(contentsOf: cached), let decoded = try? decoder.decode(T.self, from: data) {
            return decoded
        }
        return try bundled(relPath)
    }

    private func bundledData(_ relPath: String) throws -> Data {
        // Path resolution lives in ContentAssets so diagram plates and modules
        // share one lookup (see the note there on the lowercase folder name).
        guard let url = ContentAssets.bundledURL(relPath) else {
            throw ContentError.missingResource("content/" + relPath)
        }
        return try Data(contentsOf: url)
    }

    // MARK: - OTA update check

    func checkForUpdates() async {
        guard let remoteBase = Self.remoteBase else { return }
        do {
            // These two aren't individually versioned the way modules are — they're
            // the structural files (what routes exist, what categories exist) that
            // make newly-added content discoverable at all via search/browse.
            // Refresh them unconditionally whenever we're online, not just when a
            // module version bumps, and persist to Caches/ so the next cold launch
            // (via load()'s cachedOrBundled) starts from this synced state instead
            // of the original build-time bundle. Without this, a module can finish
            // syncing its own JSON and still never appear anywhere in the app.
            if let idxData = try? await fetchAndCache(remoteBase, "search-index.json"),
               let idx = try? decoder.decode(SearchIndexFile.self, from: idxData) {
                searchIndex = SearchIndex(entries: idx.entries)
            }
            if let secData = try? await fetchAndCache(remoteBase, "config/sections.json"),
               let s = try? decoder.decode(SectionsConfig.self, from: secData) {
                sections = s.sections.sorted { $0.order < $1.order }
            }

            // Persisted so the next launch (even offline) can still find the
            // paths of modules that exist only OTA — see load().
            let remote = try decoder.decode(Manifest.self, from: try await fetchAndCache(remoteBase, "manifest.json"))

            // Compare against what the app shows now: the OTA copy if one was
            // downloaded under this bundle, else the bundled copy (else nothing,
            // for a module newer than the bundle).
            var hashes = otaHashes, versions = otaVersions
            var changed: [String] = []
            for (key, m) in remote.modules {
                let current = hashes[key].map { ($0, versions[key] ?? 0) }
                    ?? bundledManifest?.modules[key].map { ($0.hash, $0.contentVersion) }
                guard Self.shouldDownload(remoteHash: m.hash, remoteVersion: m.contentVersion,
                                          currentHash: current?.0, currentVersion: current?.1 ?? 0)
                else { continue }
                let src = URLRequest(url: remoteBase.appendingPathComponent(m.path), cachePolicy: .reloadRevalidatingCacheData)
                let (moduleData, _) = try await URLSession.shared.data(for: src)
                let dest = cachesDir.appendingPathComponent(m.path)
                try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
                try moduleData.write(to: dest, options: .atomic)
                hashes[key] = m.hash
                versions[key] = m.contentVersion
                changed.append(key)
            }
            // Always adopt the published manifest, not only when something was
            // downloaded: otherwise a launch with nothing new fell back to the
            // bundled manifest and an OTA-only module (e.g. one added after this
            // build) could no longer be opened.
            manifest = remote
            if !changed.isEmpty {
                otaHashes = hashes
                otaVersions = versions
                lastUpdatedModules = changed
            }
        } catch {
            // Offline or the CDN is unreachable — we simply keep rendering from cache.
            print("[content] update check skipped: \(error)")
        }
    }

    /// Fetch `relPath` from `remoteBase` and persist it into Caches/ under the same
    /// relative path, returning the raw bytes for the caller to decode.
    @discardableResult
    private func fetchAndCache(_ remoteBase: URL, _ relPath: String) async throws -> Data {
        // Revalidate rather than trust URLSession's cache: GitHub Pages sends
        // max-age=600, which could hide a fresh deploy for ten minutes.
        let req = URLRequest(url: remoteBase.appendingPathComponent(relPath), cachePolicy: .reloadRevalidatingCacheData)
        let (data, _) = try await URLSession.shared.data(for: req)
        let dest = cachesDir.appendingPathComponent(relPath)
        try FileManager.default.createDirectory(at: dest.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: dest, options: .atomic)
        return data
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
