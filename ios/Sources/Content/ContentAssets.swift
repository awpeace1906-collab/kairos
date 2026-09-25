import Foundation
import UIKit

/// Locates files in the bundled content tree, and decodes the images among
/// them (diagram background plates).
///
/// Deliberately a plain enum rather than part of `ContentStore`. The store is
/// `@MainActor`, and view initializers are main-actor-isolated on some SDKs
/// and not on others; CI builds with an older Xcode than local, and actor
/// isolation is exactly where the two disagree. Nothing here touches shared
/// mutable state except `NSCache`, which is thread-safe.
enum ContentAssets {
    /// Resolve `relPath` (relative to the content root, e.g.
    /// "modules/procedures/x.json" or "assets/figures/plate.png") inside the
    /// app bundle.
    ///
    /// The folder reference is copied into the bundle under its on-disk name,
    /// "content" (lowercase — the `name:` in project.yml only renames the Xcode
    /// group, not the copied directory). `Bundle.url(...)` matching is
    /// case-sensitive even on the simulator's case-insensitive filesystem, so
    /// both spellings are tried.
    static func bundledURL(_ relPath: String) -> URL? {
        let file = (relPath as NSString).lastPathComponent
        let name = (file as NSString).deletingPathExtension
        let ext = (file as NSString).pathExtension

        for prefix in ["content", "Content"] {
            let subdir = prefix + "/" + (relPath as NSString).deletingLastPathComponent
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdir) {
                return url
            }
            if let resURL = Bundle.main.resourceURL {
                let direct = resURL.appendingPathComponent(prefix + "/" + relPath)
                if FileManager.default.fileExists(atPath: direct.path) {
                    return direct
                }
            }
        }
        // Last fallback: resources flattened into the bundle root.
        return Bundle.main.url(forResource: name, withExtension: ext)
    }

    /// Where an over-the-air copy of `relPath` would be written.
    static func cachedURL(_ relPath: String) -> URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("KairosContent", isDirectory: true)
            .appendingPathComponent(relPath)
    }

    private static let imageCache = NSCache<NSString, UIImage>()

    /// A decoded content image, cached for the life of the process.
    ///
    /// Prefers an OTA-cached copy, then the bundle — the same order modules
    /// use. Returns nil rather than throwing: a diagram whose plate is missing
    /// (an older app binary receiving a newer module over the air) still
    /// renders its vector overlay, which is the useful half.
    static func image(_ relPath: String) -> UIImage? {
        let key = relPath as NSString
        if let hit = imageCache.object(forKey: key) { return hit }

        let cached = cachedURL(relPath)
        let url = FileManager.default.fileExists(atPath: cached.path) ? cached : bundledURL(relPath)
        guard let url, let data = try? Data(contentsOf: url), let img = UIImage(data: data) else {
            return nil
        }
        imageCache.setObject(img, forKey: key)
        return img
    }
}
