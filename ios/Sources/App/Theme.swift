import SwiftUI

// Kairos Tier 5 palette — "Ink & Ember on Parchment" (decided 2026-09-03).
// Light-first warm-neutral ground with an ember accent, distinct from AnesCalc
// (navy + gold) and CRISIS (near-black + teal + serif). Values mirror
// web/styles.css. These are the light-mode tints; a dark-mode variant set via
// asset-catalog colours is a follow-up. Centralised here so a later swap is one file.

enum Theme {
    // Ember accent (#C6521C) — used sparingly, on the one decisive element per screen.
    static let accent = Color(red: 0.776, green: 0.322, blue: 0.110)

    /// Muted, low-chroma section tints (see --sec-* in web/styles.css).
    static func sectionColor(_ sectionID: String) -> Color {
        switch sectionID {
        case "procedures":        return Color(red: 0.357, green: 0.420, blue: 0.478) // #5B6B7A slate
        case "calculators":       return Color(red: 0.290, green: 0.278, blue: 0.329) // #4A4754 graphite
        case "drug-dosing":       return Color(red: 0.710, green: 0.376, blue: 0.180) // #B5602E terracotta
        case "reference-library": return Color(red: 0.431, green: 0.416, blue: 0.306) // #6E6A4E drab
        case "peds-module":       return Color(red: 0.541, green: 0.353, blue: 0.420) // #8A5A6B plum-rose
        default:                  return accent
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

    static func severityColor(_ severity: String?) -> Color {
        switch severity {
        case "low":       return Color(red: 0.247, green: 0.478, blue: 0.306) // #3F7A4E
        case "moderate":  return Color(red: 0.776, green: 0.322, blue: 0.110) // #C6521C (= ember)
        case "high":      return Color(red: 0.706, green: 0.196, blue: 0.165) // #B4322A
        case "critical":  return Color(red: 0.541, green: 0.125, blue: 0.125) // #8A2020
        default:          return .secondary
        }
    }
}

extension String {
    /// A route like "/calculators/cardiovascular/heart-score".
    var routeSlug: String { self }
}
