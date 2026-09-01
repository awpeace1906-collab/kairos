import SwiftUI

// Placeholder theme. The real color/font scheme is an open Tier 5 decision
// (must be visually distinct from AnesCalc and CRISIS). Centralised here so
// swapping it later is one file.

enum Theme {
    static func sectionColor(_ sectionID: String) -> Color {
        switch sectionID {
        case "procedures":        return .teal
        case "calculators":       return .indigo
        case "drug-dosing":       return .orange
        case "reference-library": return .brown
        case "peds-module":       return .pink
        default:                  return .accentColor
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
        case "low":       return .green
        case "moderate":  return .orange
        case "high":      return .red
        case "critical":  return .pink
        default:          return .secondary
        }
    }
}

extension String {
    /// A route like "/calculators/cardiovascular/heart-score".
    var routeSlug: String { self }
}
