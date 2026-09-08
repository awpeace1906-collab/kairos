import SwiftUI

// Kairos Tier 5 palette — "Ink & Ember on Parchment" (decided 2026-09-03).
// Light-first warm-neutral ground with an ember accent, distinct from AnesCalc
// (navy + gold) and CRISIS (near-black + teal + serif). Values mirror
// web/styles.css. Colours resolve through Assets.xcassets colour sets
// (AccentEmber, Section*, Severity*) so dark mode picks up the lifted dark
// variant automatically — no manual colorScheme branching needed here.

enum Theme {
    // Ember accent (#C6521C light / #E5843F dark) — used sparingly, on the one
    // decisive element per screen.
    static let accent = Color("AccentEmber", bundle: .main)

    /// Muted, low-chroma section tints (see --sec-* in web/styles.css).
    static func sectionColor(_ sectionID: String) -> Color {
        switch sectionID {
        case "procedures":        return Color("SectionProcedures", bundle: .main)   // #5B6B7A slate
        case "calculators":       return Color("SectionCalculators", bundle: .main)  // #4A4754 graphite
        case "drug-dosing":       return Color("SectionDrugDosing", bundle: .main)   // #B5602E terracotta
        case "reference-library": return Color("SectionReference", bundle: .main)    // #6E6A4E drab
        case "peds-module":       return Color("SectionPeds", bundle: .main)         // #8A5A6B plum-rose
        default:                  return accent
        }
    }

    /// Same tints as sectionColor(_:), keyed by the human title carried on a
    /// module/search-entry (RecordMeta.section, e.g. "Drug & Dosing Cards")
    /// rather than the section id — for views that only have the title on hand.
    static func sectionColor(forTitle title: String) -> Color {
        switch title {
        case "Procedures":         return sectionColor("procedures")
        case "Calculators":        return sectionColor("calculators")
        case "Drug & Dosing Cards": return sectionColor("drug-dosing")
        case "Reference Library":  return sectionColor("reference-library")
        case "Peds Module":        return sectionColor("peds-module")
        default:                   return accent
        }
    }

    static func sectionSymbol(_ sectionID: String) -> String {
        switch sectionID {
        case "procedures":        return "hand.raised"
        case "calculators":       return "function"
        case "drug-dosing":       return "pills"
        case "reference-library": return "books.vertical"
        case "peds-module":       return "figure.child"
        default:                  return "square.grid.2x2"
        }
    }

    // MARK: type — IBM Plex Sans (UI) + IBM Plex Mono (numbers, labels).
    // Mirrors web --font-sans / --font-mono. TTFs in ios/Sources/Fonts/ are
    // registered at launch (KairosApp.registerBundledFonts). PostScript names
    // are IBM Plex's abbreviated forms (…-SmBld, …-Medm).
    static func display(_ size: CGFloat) -> Font { .custom("IBMPlexSans-SmBld", size: size) }
    static func sans(_ size: CGFloat) -> Font { .custom("IBMPlexSans", size: size) }
    static func mono(_ size: CGFloat) -> Font { .custom("IBMPlexMono", size: size) }

    static func severityColor(_ severity: String?) -> Color {
        switch severity {
        case "low":       return Color("SeverityLow", bundle: .main)      // #3F7A4E
        case "moderate":  return accent                                  // #C6521C (= ember)
        case "high":      return Color("SeverityHigh", bundle: .main)     // #B4322A
        case "critical":  return Color("SeverityCritical", bundle: .main) // #8A2020
        default:          return .secondary
        }
    }
}

extension Color {
    /// Parses a "#RRGGBB" string (as used throughout content/, e.g. weight-zones.json
    /// colorHex). Falls back to .secondary on a malformed string rather than crashing.
    init(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = UInt32(s, radix: 16) else {
            self = .secondary
            return
        }
        self.init(
            red: Double((v >> 16) & 0xFF) / 255,
            green: Double((v >> 8) & 0xFF) / 255,
            blue: Double(v & 0xFF) / 255
        )
    }
}

extension String {
    /// A route like "/calculators/cardiovascular/heart-score".
    var routeSlug: String { self }
}
