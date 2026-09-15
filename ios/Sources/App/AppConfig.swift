import Foundation

/// App-level constants that are not clinical content. The GitHub repo slug lives
/// here (one place) so the "Flag as outdated" links match the web client.
/// Mirror any change in web/src/lib/appConfig.js.
enum AppConfig {
    static let githubRepo = "awpeace1906-collab/kairos"

    /// "0.1.0" — read from the bundle (MARKETING_VERSION in project.yml) so the
    /// Settings/About screen never needs a manual edit when the version bumps.
    static var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
    }

    /// Prefilled "content outdated" GitHub issue URL for a module's metadata.
    static func flagOutdatedURL(_ meta: RecordMeta) -> URL? {
        let appVersion = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "?"
        let build = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "?"
        let tier: String
        switch meta.reviewTier {
        case .level(let n): tier = String(n)
        case .stable: tier = "stable"
        case nil: tier = "—"
        }
        let title = "Outdated: \(meta.title) (\(meta.id) v\(meta.contentVersion))"
        let body = """
        **Module:** \(meta.id) (\(meta.contentType.rawValue))
        **Version:** v\(meta.contentVersion)
        **Last verified:** \(meta.lastReviewed ?? "—")
        **Next review due:** \(meta.nextReviewDue ?? "—")
        **Review tier:** \(tier)
        **Client:** iOS \(appVersion) (\(build))

        **What's outdated / newer source:**


        """
        var c = URLComponents(string: "https://github.com/\(githubRepo)/issues/new")
        c?.queryItems = [
            URLQueryItem(name: "labels", value: "content,needs-review"),
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "body", value: body),
        ]
        return c?.url
    }

    /// General "report an issue" link for the Settings screen — no module context,
    /// just points at the repo's issue tracker.
    static func newIssueURL(title: String = "", body: String = "") -> URL? {
        var c = URLComponents(string: "https://github.com/\(githubRepo)/issues/new")
        var items: [URLQueryItem] = []
        if !title.isEmpty { items.append(URLQueryItem(name: "title", value: title)) }
        if !body.isEmpty { items.append(URLQueryItem(name: "body", value: body)) }
        c?.queryItems = items.isEmpty ? nil : items
        return c?.url
    }
}
