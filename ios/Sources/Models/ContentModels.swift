import Foundation

// Codable mirrors of content/schema/*. Snake_case keys are mapped explicitly so
// the same decoder handles every file. Kept intentionally lenient — unknown
// fields are ignored, most type-specific fields are optional.

// MARK: - Shared

enum ReviewTier: Codable, Equatable {
    case level(Int)
    case stable

    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { self = .level(i); return }
        let s = try c.decode(String.self)
        self = s == "stable" ? .stable : .level(Int(s) ?? 0)
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .level(let i): try c.encode(i)
        case .stable: try c.encode("stable")
        }
    }
    var isTripwireCandidate: Bool { self == .level(1) || self == .level(3) }
}

enum ContentType: String, Codable {
    case calculator, procedure, reference
    case drugCard = "drug-card"
    case anesthesiaDrugCard = "anesthesia-drug-card"
    case pedsTool = "peds-tool"
}

struct ChangelogEntry: Codable, Hashable {
    let version: Int
    let date: String
    let change: String
}

/// A JSON scalar of unknown type (used for calculator select-option values).
enum CodableValue: Codable, Hashable {
    case string(String), number(Double), bool(Bool)
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let b = try? c.decode(Bool.self) { self = .bool(b); return }
        if let n = try? c.decode(Double.self) { self = .number(n); return }
        self = .string(try c.decode(String.self))
    }
    func encode(to encoder: Encoder) throws {}
    var stringValue: String {
        switch self {
        case .string(let s): return s
        case .number(let n): return n == n.rounded() ? String(Int(n)) : String(n)
        case .bool(let b): return b ? "1" : "0"
        }
    }
}

// MARK: - Config

struct SectionsConfig: Codable {
    let sections: [AppSection]
}

/// Named `AppSection` to avoid colliding with SwiftUI's `Section` view.
struct AppSection: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let order: Int
    let contentType: ContentType
    let coreQuestion: String
    let icon: String?
    let categories: [Category]
}

struct Category: Codable, Identifiable, Hashable {
    let id: String
    let title: String
}

struct TiersConfig: Codable {
    struct Tier: Codable {
        let tier: ReviewTier
        let label: String
        let cadenceDays: Int?
        let tripwire: Bool?
        let examples: [String]
    }
    let tiers: [Tier]
}

// MARK: - Manifest & search index

struct Manifest: Codable {
    struct Entry: Codable {
        let contentVersion: Int
        let hash: String
        let path: String
        let contentType: ContentType
        let section: String
        let reviewTier: ReviewTier?
        let nextReviewDue: String?

        enum CodingKeys: String, CodingKey {
            case contentVersion = "content_version"
            case hash, path, contentType, section
            case reviewTier = "review_tier"
            case nextReviewDue = "next_review_due"
        }
    }
    let generatedAt: String
    let schemaVersion: Int
    let modules: [String: Entry]
}

struct SearchIndexFile: Codable {
    let generatedAt: String
    let entries: [SearchEntry]
}

struct SearchEntry: Codable, Identifiable, Hashable {
    var id: String { itemID }
    let itemID: String
    let title: String
    let section: String
    let category: String
    let tags: [String]?
    let keywords: [String]?
    let contentType: ContentType
    let route: String

    enum CodingKeys: String, CodingKey {
        case itemID = "id"
        case title, section, category, tags, keywords, contentType, route
    }
}

// MARK: - Common record metadata (embedded in every module type)

struct RecordMeta: Codable {
    let id: String
    let section: String
    let category: String
    let title: String
    let contentVersion: Int
    let contentType: ContentType
    let lastReviewed: String?
    let nextReviewDue: String?
    let reviewTier: ReviewTier?
    let sources: [String]?
    let changelog: [ChangelogEntry]?
    let flags: [String]?

    enum CodingKeys: String, CodingKey {
        case id, section, category, title, contentType, sources, changelog, flags
        case contentVersion = "content_version"
        case lastReviewed = "last_reviewed"
        case nextReviewDue = "next_review_due"
        case reviewTier = "review_tier"
    }
}

// MARK: - Calculator

struct Calculator: Codable {
    let meta: RecordMeta
    let engine: Engine
    let settings: [String]?
    let purpose: String
    let notes: String?
    let inputs: [Input]?
    let items: [Item]?
    let formulas: [Formula]?
    let tiers: [Tier]?
    let interpretation: [Band]
    let buildNote: String?

    enum Engine: String, Codable { case additive, formula, classification, external }

    struct Input: Codable, Identifiable, Hashable {
        var id: String { key }
        let key: String
        let label: String
        let type: String
        let unit: String?
        let min: Double?
        let max: Double?
        let options: [SelectOption]?
    }
    struct SelectOption: Codable, Identifiable, Hashable {
        var id: String { label }
        let label: String
        let value: CodableValue
        var valueString: String { value.stringValue }
    }
    struct Item: Codable, Identifiable, Hashable {
        var id: String { key }
        let key: String
        let label: String
        let help: String?
        let options: [Option]
    }
    struct Option: Codable, Hashable {
        let label: String
        let points: Double
    }
    struct Formula: Codable, Identifiable, Hashable {
        var id: String { key }
        let key: String
        let label: String
        let expression: String
        let unit: String?
        let precision: Int?
    }
    struct Tier: Codable, Hashable {
        let label: String
        let description: String
        let mortality: String?
    }
    struct Band: Codable, Hashable {
        let min: Double?
        let max: Double?
        let forKey: String?
        let label: String
        let detail: String?
        let risk: String?
        let disposition: String?
        let severity: String?
    }

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        engine = try c.decode(Engine.self, forKey: .engine)
        settings = try c.decodeIfPresent([String].self, forKey: .settings)
        purpose = try c.decode(String.self, forKey: .purpose)
        notes = try c.decodeIfPresent(String.self, forKey: .notes)
        inputs = try c.decodeIfPresent([Input].self, forKey: .inputs)
        items = try c.decodeIfPresent([Item].self, forKey: .items)
        formulas = try c.decodeIfPresent([Formula].self, forKey: .formulas)
        tiers = try c.decodeIfPresent([Tier].self, forKey: .tiers)
        interpretation = try c.decode([Band].self, forKey: .interpretation)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws { /* read-only in the app */ }

    private enum CodingKeys: String, CodingKey {
        case engine, settings, purpose, notes, inputs, items, formulas, tiers, interpretation, buildNote
    }
}

// MARK: - Drug card

struct DrugCard: Codable {
    let meta: RecordMeta
    let purpose: String
    let population: String?
    let weightBasis: String?
    let doses: [Dose]
    let contraindications: [String]?
    let reversal: String?
    let buildNote: String?

    struct Dose: Codable, Identifiable, Hashable {
        var id: String { indication }
        let indication: String
        let route: String
        let rule: Rule
        let notes: String?
    }
    struct Rule: Codable, Hashable {
        let perKg: Double
        let perKgHigh: Double?
        let unit: String?
        let maxDose: Double?
        let minDose: Double?
        let maxDoseUnit: String?
        let concentration: String?
        let mlPerUnit: Double?
        let repeatText: String?
        enum CodingKeys: String, CodingKey {
            case perKg, perKgHigh, unit, maxDose, minDose, maxDoseUnit, concentration, mlPerUnit
            case repeatText = "repeat"
        }
    }

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        purpose = try c.decode(String.self, forKey: .purpose)
        population = try c.decodeIfPresent(String.self, forKey: .population)
        weightBasis = try c.decodeIfPresent(String.self, forKey: .weightBasis)
        doses = try c.decode([Dose].self, forKey: .doses)
        contraindications = try c.decodeIfPresent([String].self, forKey: .contraindications)
        reversal = try c.decodeIfPresent(String.self, forKey: .reversal)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey {
        case purpose, population, weightBasis, doses, contraindications, reversal, buildNote
    }
}

// MARK: - Anesthesia drug card (AnesCalc-origin)

struct AnesthesiaDrugCard: Codable {
    let meta: RecordMeta
    let brandName: String?
    let tallManLetters: String?
    let drugClass: String
    let drugClassLabel: String
    let mechanism: String
    let onset: String
    let duration: String
    let dosing: String
    let cautions: [String]
    let pearls: [String]
    let reversal: String?

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        brandName = try c.decodeIfPresent(String.self, forKey: .brandName)
        tallManLetters = try c.decodeIfPresent(String.self, forKey: .tallManLetters)
        drugClass = try c.decode(String.self, forKey: .drugClass)
        drugClassLabel = try c.decode(String.self, forKey: .drugClassLabel)
        mechanism = try c.decode(String.self, forKey: .mechanism)
        onset = try c.decode(String.self, forKey: .onset)
        duration = try c.decode(String.self, forKey: .duration)
        dosing = try c.decode(String.self, forKey: .dosing)
        cautions = try c.decode([String].self, forKey: .cautions)
        pearls = try c.decode([String].self, forKey: .pearls)
        reversal = try c.decodeIfPresent(String.self, forKey: .reversal)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey {
        case brandName, tallManLetters, drugClass, drugClassLabel, mechanism, onset, duration, dosing, cautions, pearls, reversal
    }
}

// MARK: - Reference

struct ReferenceDoc: Codable {
    let meta: RecordMeta
    let summary: String?
    let body: [Block]
    let buildNote: String?

    struct Block: Codable, Hashable {
        let type: String
        let level: Int?
        let text: String?
        let items: [String]?
        let columns: [String]?
        let rows: [[String]]?
        let tone: String?
    }

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        body = try c.decode([Block].self, forKey: .body)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey { case summary, body, buildNote }
}

// MARK: - Procedure

struct Procedure: Codable {
    let meta: RecordMeta
    let purpose: String
    let outputType: String
    let entryPrompt: String?
    let crossLinks: [String]?
    let nodes: [Node]?
    let checklist: [String]?
    let noteTemplate: String?
    let buildNote: String?

    struct Node: Codable, Identifiable, Hashable {
        var id: String { nodeID }
        let nodeID: String
        let type: String
        let prompt: String?
        let body: String?
        let choices: [Choice]?
        enum CodingKeys: String, CodingKey {
            case nodeID = "id"
            case type, prompt, body, choices
        }
    }
    struct Choice: Codable, Hashable {
        let label: String
        let next: String
    }

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        purpose = try c.decode(String.self, forKey: .purpose)
        outputType = try c.decode(String.self, forKey: .outputType)
        entryPrompt = try c.decodeIfPresent(String.self, forKey: .entryPrompt)
        crossLinks = try c.decodeIfPresent([String].self, forKey: .crossLinks)
        nodes = try c.decodeIfPresent([Node].self, forKey: .nodes)
        checklist = try c.decodeIfPresent([String].self, forKey: .checklist)
        noteTemplate = try c.decodeIfPresent(String.self, forKey: .noteTemplate)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey {
        case purpose, outputType, entryPrompt, crossLinks, nodes, checklist, noteTemplate, buildNote
    }
}

// MARK: - Peds tool

struct PedsTool: Codable {
    let meta: RecordMeta
    let kind: String
    let purpose: String
    let ageRange: String?
    let sourceOfTruth: [String]?
    let embeddedCalculator: Calculator?
    let body: [ReferenceDoc.Block]?
    let buildNote: String?

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        kind = try c.decode(String.self, forKey: .kind)
        purpose = try c.decode(String.self, forKey: .purpose)
        ageRange = try c.decodeIfPresent(String.self, forKey: .ageRange)
        sourceOfTruth = try c.decodeIfPresent([String].self, forKey: .sourceOfTruth)
        embeddedCalculator = try c.decodeIfPresent(Calculator.self, forKey: .embeddedCalculator)
        body = try c.decodeIfPresent([ReferenceDoc.Block].self, forKey: .body)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey {
        case kind, purpose, ageRange, sourceOfTruth, embeddedCalculator, body, buildNote
    }
}

// MARK: - Weight zones

struct WeightZonesConfig: Codable {
    let scheme: String
    let disclaimer: String
    let ageEstimate: AgeEstimate
    let zones: [Zone]

    struct AgeEstimate: Codable {
        let note: String
        let formulas: [Formula]
        struct Formula: Codable {
            let ageBandLabel: String
            let minMonths: Double
            let maxMonths: Double
            let expression: String
        }
    }
    struct Zone: Codable, Identifiable, Hashable {
        var id: Int { zone }
        let zone: Int
        let color: String
        let weightMin: Double
        let weightMax: Double
        let equipment: Equipment
        let note: String?
        enum CodingKeys: String, CodingKey {
            case zone, color, equipment, note
            case weightMin = "weight_min"
            case weightMax = "weight_max"
        }
        struct Equipment: Codable, Hashable {
            let ettUncuffed: String?
            let lma: String?
            let blade: String?
            let defibPads: String?
            let bpCuff: String?
        }
    }
}
