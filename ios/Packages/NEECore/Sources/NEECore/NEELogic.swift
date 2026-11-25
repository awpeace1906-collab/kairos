import Foundation

// Codable model of nee-logic.json (logic v1.2.0). Structure only: every
// factor, unit, threshold and word shown to the user is read from the JSON at
// runtime. Keys are mapped explicitly (no snake_case conversion) because agent
// ids are also dictionary keys.

public struct Fraction: Decodable, Equatable {
    public let num: Double
    public let den: Double
    public var value: Double { num / den }
}

public struct NEELogic: Decodable {
    public let logicVersion: String
    public let id: String
    public let title: String
    public let ui: UI
    public let output: Output
    public let weight: Weight
    public let norepinephrineSalt: Salt
    public let agents: [Agent]
    public let formulas: [Formula]
    public let messages: [String: String]
    public let contextNotes: [ContextNote]
    public let citations: [String: String]

    enum CodingKeys: String, CodingKey {
        case logicVersion = "logic_version", id, title, ui, output, weight
        case norepinephrineSalt = "norepinephrine_salt", agents, formulas, messages
        case contextNotes = "context_notes", citations
    }

    public static func load(from data: Data) throws -> NEELogic { try JSONDecoder().decode(NEELogic.self, from: data) }

    public var defaultFormula: Formula? { formulas.first { $0.isDefault } }
    public func formula(_ id: String?) -> Formula? { formulas.first { $0.id == id } ?? defaultFormula }
    public func agent(_ id: String) -> Agent? { agents.first { $0.id == id } }
    public func note(_ id: String) -> ContextNote? { contextNotes.first { $0.id == id } }

    public struct UI: Decodable {
        public let formulaLabel, weightLabel, weightRequiredMarker, saltLabel, notInFormulaMarker: String
        public let adjunctsHeading, resultLabel, adjunctLine, breakdownHeading, sourcesHeading, clearAll, sourcesRule: String
        enum CodingKeys: String, CodingKey {
            case formulaLabel = "formula_label", weightLabel = "weight_label", weightRequiredMarker = "weight_required_marker"
            case saltLabel = "salt_label", notInFormulaMarker = "not_in_formula_marker", adjunctsHeading = "adjuncts_heading"
            case resultLabel = "result_label", adjunctLine = "adjunct_line", breakdownHeading = "breakdown_heading"
            case sourcesHeading = "sources_heading", clearAll = "clear_all", sourcesRule = "sources_rule"
        }
    }

    public struct Output: Decodable {
        public let primaryUnit: String
        public let secondaryUnit: String
        public let adjunctUnit: String
        public let displayDecimals: Decimals
        enum CodingKeys: String, CodingKey {
            case primaryUnit = "primary_unit", secondaryUnit = "secondary_unit", adjunctUnit = "adjunct_unit"
            case displayDecimals = "display_decimals"
        }
        public struct Decimals: Decodable {
            public let neeMcgKgMin, contributionMcgKgMin, neeMcgMin, adjunctMcgKgMin, doseCanonical: Int
            enum CodingKeys: String, CodingKey {
                case neeMcgKgMin = "nee_mcg_kg_min", contributionMcgKgMin = "contribution_mcg_kg_min"
                case neeMcgMin = "nee_mcg_min", adjunctMcgKgMin = "adjunct_mcg_kg_min", doseCanonical = "dose_canonical"
            }
        }
    }

    public struct Weight: Decodable {
        public let unit: String
        public let minInclusive: Double
        public let maxInclusive: Double
        enum CodingKeys: String, CodingKey { case unit, minInclusive = "min_inclusive", maxInclusive = "max_inclusive" }
    }

    public struct Salt: Decodable {
        public let appliesToAgent: String
        public let defaultId: String
        public let options: [Option]
        public let noteId: String
        enum CodingKeys: String, CodingKey {
            case appliesToAgent = "applies_to_agent", defaultId = "default", options, noteId = "note_id"
        }
        public struct Option: Decodable, Identifiable {
            public let id: String
            public let label: String
            public let factorToBase: Fraction
            enum CodingKeys: String, CodingKey { case id, label, factorToBase = "factor_to_base" }
        }
    }

    public struct Agent: Decodable, Identifiable {
        public let id: String
        public let label: String
        public let canonicalUnit: String
        public let inputUnits: [InputUnit]
        public let role: String
        enum CodingKeys: String, CodingKey { case id, label, canonicalUnit = "canonical_unit", inputUnits = "input_units", role }
        public var isAdjunct: Bool { role == "adjunct" }
        public var defaultUnit: String? { (inputUnits.first { $0.isDefault } ?? inputUnits.first)?.unit }
        public struct InputUnit: Decodable {
            public let unit: String
            public let multiply: Fraction
            public let perWeight: Bool
            public let isDefault: Bool
            enum CodingKeys: String, CodingKey { case unit, multiply, perWeight = "per_weight", isDefault = "default" }
            public init(from decoder: Decoder) throws {
                let c = try decoder.container(keyedBy: CodingKeys.self)
                unit = try c.decode(String.self, forKey: .unit)
                multiply = try c.decode(Fraction.self, forKey: .multiply)
                perWeight = try c.decode(Bool.self, forKey: .perWeight)
                isDefault = try c.decodeIfPresent(Bool.self, forKey: .isDefault) ?? false
            }
        }
    }

    public struct Formula: Decodable, Identifiable {
        public let id: String
        public let label: String
        public let isDefault: Bool
        public let citationId: String
        public let description: String
        public let factors: [String: Factor]
        enum CodingKeys: String, CodingKey { case id, label, isDefault = "default", citationId = "citation_id", description, factors }
        public struct Factor: Decodable {
            public let factor: Fraction
            public let publishedAs: String
            enum CodingKeys: String, CodingKey { case factor, publishedAs = "published_as" }
        }
    }

    public struct ContextNote: Decodable, Identifiable {
        public let id: String
        public let type: String
        public let showWhenAll: [Condition]?
        public let text: String
        public let citationId: String
        enum CodingKeys: String, CodingKey { case id, type, showWhenAll = "show_when_all", text, citationId = "citation_id" }
        public struct Condition: Decodable {
            public let agent: String?
            public let canonicalDoseGte: Fraction?
            public let absent: Bool?
            public let adjunctEstimatePresent: Bool?
            enum CodingKeys: String, CodingKey {
                case agent, canonicalDoseGte = "canonical_dose_gte", absent, adjunctEstimatePresent = "adjunct_estimate_present"
            }
        }
    }
}
