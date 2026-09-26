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
    let settingEmphasis: [String]?
    let audience: [String]?
    let crossListIn: [CrossListPlacement]?

    struct CrossListPlacement: Codable, Hashable {
        let section: String
        let category: String
    }

    /// True when this module is for the pediatric / neonatal population.
    var isPeds: Bool {
        (audience?.contains("peds") ?? false) || (audience?.contains("neonate") ?? false) || section == "Peds Module"
    }
    /// The category to file this entry under when browsing `inSection` (its own,
    /// or the matching crossListIn placement).
    func category(inSection s: String) -> String {
        section == s ? category : (crossListIn?.first { $0.section == s }?.category ?? category)
    }
    func appears(inSection s: String) -> Bool {
        section == s || (crossListIn?.contains { $0.section == s } ?? false)
    }

    enum CodingKeys: String, CodingKey {
        case itemID = "id"
        case title, section, category, tags, keywords, contentType, route, settingEmphasis, audience, crossListIn
    }

    // Explicit memberwise init so the optional nav-lens fields (`settingEmphasis`,
    // `audience`, `crossListIn` — often absent) default to nil — keeps older call
    // sites and tests compiling.
    init(itemID: String, title: String, section: String, category: String,
         tags: [String]? = nil, keywords: [String]? = nil, contentType: ContentType,
         route: String, settingEmphasis: [String]? = nil,
         audience: [String]? = nil, crossListIn: [CrossListPlacement]? = nil) {
        self.itemID = itemID
        self.title = title
        self.section = section
        self.category = category
        self.tags = tags
        self.keywords = keywords
        self.contentType = contentType
        self.route = route
        self.settingEmphasis = settingEmphasis
        self.audience = audience
        self.crossListIn = crossListIn
    }
}

/// content/config/pinned.json — curated home-screen shortcuts.
struct PinnedConfig: Codable {
    let pinned: [Entry]
    struct Entry: Codable { let id: String; let label: String; let blurb: String? }
}
struct PinnedShortcut: Identifiable, Hashable {
    var id: String { route }
    let label: String
    let blurb: String
    let route: String
}

/// content/config/settings.json — the four care settings the app can be lensed to.
struct SettingsConfig: Codable {
    let settings: [CareSetting]
    struct CareSetting: Codable, Identifiable, Hashable {
        let id: String
        let label: String
        let order: Int
    }
}

/// Emphasis rank for the care-setting lens (DIRECTIONS_FORWARD §1). Lower = more
/// relevant; Int.max = this setting isn't listed (entry keeps its default place).
func careEmphasisRank(_ entry: SearchEntry, _ setting: String?) -> Int {
    guard let setting, let arr = entry.settingEmphasis, let i = arr.firstIndex(of: setting) else { return .max }
    return i
}

/// content/sources-index.json — the complete, de-duplicated bibliography for the
/// Settings -> Sources page. Generated by tools/build-sources-index.mjs.
struct SourcesIndexFile: Codable {
    let generatedAt: String
    let groupOrder: [String]
    let count: Int
    let items: [SourceItem]
}

struct SourceItem: Codable, Identifiable {
    var id: String { text }
    let text: String
    let group: String
    let usedBy: [SourceUsage]
}

struct SourceUsage: Codable, Hashable {
    let id: String
    let title: String
    let section: String
    let route: String
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
    let plot: Plot?
    let buildNote: String?
    /// engine == .builtin only: which code-backed tool renders this module.
    let tool: String?
    /// engine == .builtin, tool == "ekg-axis": every string the axis tool shows.
    let axisContent: AxisToolContent?

    enum Engine: String, Codable { case additive, formula, classification, external, builtin }

    /// Optional 2-D plot (e.g. a treatment nomogram) rendered next to the result.
    /// Curve expressions use the free variable `x`; the marker is read from the
    /// inputs named by x.key / y.key. Mirrors calculator.schema.json `plot`.
    struct Plot: Codable, Hashable {
        let kind: String
        let caption: String?
        let x: Axis
        let y: Axis
        let curves: [Curve]

        struct Axis: Codable, Hashable {
            let key: String
            let label: String
            let min: Double
            let max: Double
            let unit: String?
        }
        struct Curve: Codable, Hashable {
            let label: String
            let expression: String
            let tone: String?
        }
    }

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
        plot = try c.decodeIfPresent(Plot.self, forKey: .plot)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
        tool = try c.decodeIfPresent(String.self, forKey: .tool)
        axisContent = tool == "ekg-axis" ? try c.decodeIfPresent(AxisToolContent.self, forKey: .toolContent) : nil
    }
    func encode(to encoder: Encoder) throws { /* read-only in the app */ }

    private enum CodingKeys: String, CodingKey {
        case engine, settings, purpose, notes, inputs, items, formulas, tiers, interpretation, plot, buildNote, tool, toolContent
    }
}

/// Copy for the EKG axis tool (calculator.schema.json#/$defs/ekgAxisContent).
/// The engine (Calc/AxisEngine.swift) returns keys; these maps turn them into text.
struct AxisToolContent: Codable, Hashable {
    struct Mode: Codable, Hashable, Identifiable {
        let id: String
        let engineMode: String?
        let `default`: Bool?
        let label: String
        let help: String
        let leads: [String]?
    }
    struct Modifier: Codable, Hashable, Identifiable { let id: String; let label: String }
    struct Category: Codable, Hashable { let label: String; let range: String?; let detail: String? }
    struct Flag: Codable, Hashable { let level: String; let text: String; let checklist: String? }
    struct Checklist: Codable, Hashable { let title: String; let items: [String]; let caveat: String? }
    struct Status: Codable, Hashable {
        let inconsistent: String?
        let ambiguous: String?
        let indeterminate: String?
        let needTwoLeads: String?
        let noInput: String?
        let errors: [String: String]
        enum CodingKeys: String, CodingKey {
            case inconsistent, ambiguous, indeterminate, errors
            case needTwoLeads = "need_two_leads", noInput = "no_input"
        }
        func message(_ status: String) -> String? {
            switch status {
            case "inconsistent": return inconsistent
            case "ambiguous": return ambiguous
            case "indeterminate": return indeterminate
            case "need_two_leads": return needTwoLeads
            case "no_input": return noInput
            default: return errors[status]
            }
        }
    }
    struct Peds: Codable, Hashable {
        struct Band: Codable, Hashable { let age: String; let range: String }
        let bands: [Band]
        let note: String
    }

    let modes: [Mode]
    let modifiers: [Modifier]
    let qrsCategories: [String: Category]
    let pCategories: [String: Category]
    let tCategories: [String: Category]
    let qrsTCategories: [String: Category]
    let flags: [String: Flag]
    let warnings: [String: String]
    let statusMessages: Status
    let checklists: [String: Checklist]
    let differentials: [String: [String]]
    let peds: Peds
    let clinicalTakeaway: String
    let whyThisMatters: String
}

// MARK: - Drug card

struct DrugCard: Codable {
    let meta: RecordMeta
    let purpose: String
    let population: String?
    let weightBasis: String?
    let obeseWeightBasis: String?
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
        obeseWeightBasis = try c.decodeIfPresent(String.self, forKey: .obeseWeightBasis)
        doses = try c.decode([Dose].self, forKey: .doses)
        contraindications = try c.decodeIfPresent([String].self, forKey: .contraindications)
        reversal = try c.decodeIfPresent(String.self, forKey: .reversal)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey {
        case purpose, population, weightBasis, obeseWeightBasis, doses, contraindications, reversal, buildNote
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
    let whyThisMatters: String?
    let clinicalTakeaway: String?
    let body: [Block]
    let buildNote: String?

    struct Block: Codable, Hashable {
        let type: String
        let level: Int?
        let text: String?
        /// `type == "list"`: entries, possibly nested.
        let items: [ListItem]?
        /// `type == "list"`: number this level instead of bulleting it.
        let ordered: Bool?
        let columns: [String]?
        let rows: [[String]]?
        let tone: String?
        let diagram: Diagram?
    }

    init(from decoder: Decoder) throws {
        meta = try RecordMeta(from: decoder)
        let c = try decoder.container(keyedBy: CodingKeys.self)
        summary = try c.decodeIfPresent(String.self, forKey: .summary)
        whyThisMatters = try c.decodeIfPresent(String.self, forKey: .whyThisMatters)
        clinicalTakeaway = try c.decodeIfPresent(String.self, forKey: .clinicalTakeaway)
        body = try c.decode([Block].self, forKey: .body)
        buildNote = try c.decodeIfPresent(String.self, forKey: .buildNote)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey { case summary, whyThisMatters, clinicalTakeaway, body, buildNote }
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
        /// Sub-steps belonging to this step, rendered under `body`.
        let substeps: NestedList?
        let diagram: Diagram?
        enum CodingKeys: String, CodingKey {
            case nodeID = "id"
            case type, prompt, body, choices, substeps, diagram
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
    let obesityFlagRatio: Double?
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
        let colorHex: String?
        let weightMin: Double
        let weightMax: Double
        let equipment: Equipment
        let note: String?
        enum CodingKeys: String, CodingKey {
            case zone, color, colorHex, equipment, note
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

// MARK: - Diagram

/// An original declarative vector figure (common.schema.json#/$defs/diagram).
/// Deliberately not raster/video: renders natively on both clients, ships inside
/// the offline content bundle, themes itself through semantic color tokens, and
/// carries no third-party licensing. Web mirror: renderDiagram() in content.js.
/// One entry in a content list.
///
/// The JSON is heterogeneous by design — a plain string is a leaf, and the
/// object form carries children so a numbered step can hold its own
/// sub-steps. Mixing the two in one array is allowed, and every flat list
/// authored before nesting existed still decodes. See
/// common.schema.json#/$defs/listItem.
struct ListItem: Codable, Hashable, Identifiable {
    let text: String
    /// Number THIS item's children. Independent of the parent's own numbering.
    let ordered: Bool
    let items: [ListItem]?

    /// Stable within a single render — list entries have no ids in the data,
    /// and the text is what distinguishes them on screen.
    var id: String { "\(text)|\(items?.count ?? 0)" }

    /// Built in code by RichText, for list lines inside a prose field.
    init(text: String, ordered: Bool = false, items: [ListItem]? = nil) {
        self.text = text
        self.ordered = ordered
        self.items = items
    }

    init(from decoder: Decoder) throws {
        if let flat = try? decoder.singleValueContainer().decode(String.self) {
            text = flat
            ordered = false
            items = nil
            return
        }
        let c = try decoder.container(keyedBy: CodingKeys.self)
        text = try c.decode(String.self, forKey: .text)
        ordered = try c.decodeIfPresent(Bool.self, forKey: .ordered) ?? false
        items = try c.decodeIfPresent([ListItem].self, forKey: .items)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey { case text, ordered, items }
}

/// A list plus its own numbering flag, for fields that hold exactly one list.
struct NestedList: Codable, Hashable {
    let ordered: Bool
    let items: [ListItem]

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        ordered = try c.decodeIfPresent(Bool.self, forKey: .ordered) ?? false
        items = try c.decode([ListItem].self, forKey: .items)
    }
    func encode(to encoder: Encoder) throws {}
    private enum CodingKeys: String, CodingKey { case ordered, items }
}

struct Diagram: Codable, Hashable {
    let title: String?
    let caption: String?
    /// [minX, minY, width, height]
    let viewBox: [Double]
    /// Optional raster background (an anatomical plate). Shapes are authored in
    /// its pixel coordinates; the viewBox is a crop window onto it.
    let image: Plate?
    let shapes: [Shape]

    struct Plate: Codable, Hashable {
        /// Relative to the content root, e.g. "assets/figures/gray1215.png".
        let src: String
        let width: Double
        let height: Double
        /// Top-left in viewBox units; defaults to the origin.
        let at: [Double]?
        let credit: String
        let license: String
        let sourceUrl: String?
        let sha1: String?
    }

    struct Shape: Codable, Hashable {
        let kind: String
        let d: String?
        let points: [[Double]]?
        let from: [Double]?
        let to: [Double]?
        let at: [Double]?
        let size: [Double]?
        let r: Double?
        let rx: Double?
        let ry: Double?
        let text: String?
        let fontSize: Double?
        let anchor: String?
        let weight: String?
        let fill: String?
        let stroke: String?
        let strokeWidth: Double?
        let dash: Bool?
        let opacity: Double?
    }
}
