import Foundation
import SwiftUI

// Tier 6: entered data survives backgrounding / app-switch and is cleared only by
// a genuine full closeout. Persisted to a Caches file; on a cold launch that was
// NOT preceded by a background transition, we treat it as a fresh start and clear.
// Mirrors the intent of web/src/lib/session.js (sessionStorage).

@MainActor
final class SessionStore: ObservableObject {

    private let fileURL: URL = {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("kairos.session.json")
    }()
    private let backgroundMarker = "kairos.didBackground"

    @Published private var screens: [String: [String: String]] = [:]

    init() {
        let launchedAfterBackground = UserDefaults.standard.bool(forKey: backgroundMarker)
        if launchedAfterBackground, let data = try? Data(contentsOf: fileURL),
           let decoded = try? JSONDecoder().decode([String: [String: String]].self, from: data) {
            screens = decoded
        } else {
            clearAll()   // cold start with no prior background -> fresh session
        }
        UserDefaults.standard.set(false, forKey: backgroundMarker)
    }

    /// Call from .onChange(of: scenePhase).
    func scenePhaseChanged(_ phase: ScenePhase) {
        if phase == .background {
            UserDefaults.standard.set(true, forKey: backgroundMarker)
            persist()
        }
    }

    func value(_ route: String, _ field: String) -> String { screens[route]?[field] ?? "" }
    func fields(_ route: String) -> [String: String] { screens[route] ?? [:] }

    func set(_ route: String, _ field: String, _ value: String) {
        if value.isEmpty { screens[route]?[field] = nil }
        else { screens[route, default: [:]][field] = value }
        persist()
    }

    func clearField(_ route: String, _ field: String) { screens[route]?[field] = nil; persist() }
    func clearScreen(_ route: String) { screens[route] = nil; persist() }
    func clearAll() { screens = [:]; try? FileManager.default.removeItem(at: fileURL) }

    private func persist() {
        guard let data = try? JSONEncoder().encode(screens) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
