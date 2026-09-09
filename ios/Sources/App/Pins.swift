import Foundation

/// Home-screen pins. Backed by a single @AppStorage string:
///   ""   → not customized yet, use the curated defaults from config/pinned.json
///   "-"  → customized to empty
///   "a,b,c" → an explicit ordered id list
/// (module ids match ^[a-z0-9]+(-[a-z0-9]+)*$, so a bare "-" is a safe sentinel.)
enum Pins {
    static let key = "kairos.pins"
    static let max = 8

    static func ids(raw: String, curated: [String]) -> [String] {
        if raw.isEmpty { return curated }
        if raw == "-" { return [] }
        return raw.split(separator: ",").map(String.init)
    }

    static func isPinned(_ id: String, raw: String, curated: [String]) -> Bool {
        ids(raw: raw, curated: curated).contains(id)
    }

    /// Returns the new raw string after toggling `id`.
    static func toggled(_ id: String, raw: String, curated: [String]) -> String {
        var list = ids(raw: raw, curated: curated)
        if let i = list.firstIndex(of: id) {
            list.remove(at: i)
        } else {
            list.append(id)
            if list.count > max { list.removeFirst(list.count - max) }
        }
        return list.isEmpty ? "-" : list.joined(separator: ",")
    }
}
