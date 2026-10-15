import Foundation

// Codable model of extubation-logic.json (cv-extubation-logic v1.4). Adapted
// from AnesCalc's ExtubationLogic.swift: public API for use from an app
// target, the v1.3 ui keys, and alert order taken from the JSON text (see
// ExtubationLogic.load). Holds structure only; every word shown to the user
// is read from the JSON at runtime.

// MARK: - Top-level model

public struct ExtubationLogic: Decodable {
    public let schema: String
    public let version: String
    public let updated: String
    public let ui: ExtubationUI
    public let tracks: [String: TrackInfo]
    public let screens: [ExtubationScreen]
    public let flow: [String: [FlowStep]]
    public let flowRules: [String]
    public let outcomes: [String: Outcome]
    public let outcomeRules: [OutcomeRule]
    public let outcomeRulesNote: String
    public private(set) var alerts: OrderedAlerts
    public let alertRules: [String]
    public let resultLayout: [String]
    public let cardLayout: [String]
    public let layoutRules: [String]?
    public let sources: [String: ExtubationSource]

    /// Decode, then put the alerts in the order they appear in the JSON text.
    /// JSONDecoder does not promise to keep object-key order, and alert order
    /// within each color group is part of the logic (alertRules).
    public static func load(from data: Data) throws -> ExtubationLogic {
        var logic = try JSONDecoder().decode(ExtubationLogic.self, from: data)
        let order = try JSONKeyOrder.keys(ofObjectAt: ["alerts"], in: data)
        logic.alerts = try logic.alerts.reordered(by: order)
        return logic
    }

    public func screen(_ id: String) -> ExtubationScreen? { screens.first { $0.id == id } }
}

// MARK: - UI strings

public struct ExtubationUI: Decodable {
    public let disclaimer: String
    public let recommendationPrefix: String
    public let buttons: ButtonLabels
    public let stepLabel: String
    public let acknowledge: String
    public let card: CardLabels
}

public struct ButtonLabels: Decodable {
    public let next: String
    public let back: String
    public let reset: String
    public let print: String
    public let evidence: String
    public let resetConfirm: String
    public let startOverConfirm: String
    public let confirm: String
    public let cancel: String
    public let yes: String
    public let no: String
}

public struct CardLabels: Decodable {
    public let header: String
    public let patientLabel: String
}

public struct TrackInfo: Decodable {
    public let title: String
    public let subtitle: String
    public let totalSteps: Int
}

// MARK: - Screens

public struct ExtubationScreen: Decodable, Identifiable {
    public let id: String
    public let track: String?
    public let step: Int
    public let type: ScreenType
    public let title: String
    public let prompt: String
    public let options: [ScreenOption]?
    public let items: [ChecklistItem]?
    public let fields: [ScreenTextField]?
    public let info: String?
    public let infoSources: [String]?
    public let note: String?
    public let noteSources: [String]?
    public let showIf: Condition?
    public let required: Bool?
}

public enum ScreenType: String, Decodable {
    case singleChoice = "single_choice"
    case yesNo        = "yes_no"
    case checklist
    case textFields   = "text_fields"
}

public struct ScreenOption: Decodable, Identifiable {
    public let id: String
    public let label: String
}

public struct ChecklistItem: Decodable, Identifiable {
    public let id: String
    public let label: String
    public let hard: Bool?
}

public struct ScreenTextField: Decodable, Identifiable {
    public let id: String
    public let label: String
}

// MARK: - Flow

public struct FlowStep: Decodable {
    public let at: String
    public let stopIf: Condition?
    public let outcome: String?
}

// MARK: - Outcomes

public struct Outcome: Decodable {
    public let `class`: String
    public let chip: String
    public let title: String
    public let text: String
    public let why: WhySpec
    public let sources: [String]
}

public struct WhySpec: Decodable {
    public let fixed: [String]?
    public let checked: String?
    public let uncheckedHard: String?
    public let prefix: String?
}

public struct OutcomeRule: Decodable {
    public let track: String
    public let when: Condition
    public let outcome: String
}

// MARK: - Alerts (JSON order; see ExtubationLogic.load)

public struct OrderedAlerts: Decodable {
    public let entries: [(id: String, def: AlertDef)]

    init(entries: [(id: String, def: AlertDef)]) { self.entries = entries }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)
        entries = try container.allKeys.map { key in
            (id: key.stringValue, def: try container.decode(AlertDef.self, forKey: key))
        }
    }

    func reordered(by order: [String]) throws -> OrderedAlerts {
        let byId = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0.def) })
        guard Set(order) == Set(byId.keys), order.count == byId.count else {
            throw ExtubationError.malformedLogic("alert keys in the JSON text do not match the decoded alerts")
        }
        return OrderedAlerts(entries: order.map { (id: $0, def: byId[$0]!) })
    }

    public subscript(_ id: String) -> AlertDef? { entries.first { $0.id == id }?.def }
    public func sources(for id: String) -> [String] { self[id]?.sources ?? [] }
}

public struct AlertDef: Decodable {
    public let level: String
    public let text: String
    public let when: Condition
    public let items: AlertItemsSpec?
    public let requiresAck: Bool?
    public let sources: [String]
    public let tracks: [String]
    public let onStop: Bool
}

public struct AlertItemsSpec: Decodable {
    public let unchecked: String?
    public let uncheckedSoft: String?

    public var mode: String { uncheckedSoft != nil ? "uncheckedSoft" : "unchecked" }
    public var screenId: String? { uncheckedSoft ?? unchecked }
}

// MARK: - Conditions

public struct Condition: Decodable {
    public let always: Bool?
    public let count: String?
    public let gte: Int?
    public let eq: ConditionEq?
    public let answer: String?
    public let anyUnchecked: String?
    public let hardOnly: Bool?
    public let softOnly: Bool?
}

public enum ConditionEq: Decodable {
    case int(Int)
    case string(String)

    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let i = try? c.decode(Int.self) { self = .int(i); return }
        self = .string(try c.decode(String.self))
    }

    func matchesInt(_ n: Int) -> Bool {
        if case .int(let i) = self { return i == n }
        return false
    }

    func matchesString(_ s: String?) -> Bool {
        if case .string(let v) = self { return v == s }
        return false
    }
}

// MARK: - Sources

public struct ExtubationSource: Decodable {
    public let short: String
    public let full: String
}

// MARK: - Errors

public enum ExtubationError: Error, Equatable {
    case unknownCondition
    case noOutcome(track: String)
    case malformedLogic(String)
}

// MARK: - Helpers

struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { nil }
}

/// Reads the keys of one JSON object, in the order they appear in the text.
/// A minimal scanner (strings, escapes, nesting), enough for well-formed JSON.
enum JSONKeyOrder {
    static func keys(ofObjectAt path: [String], in data: Data) throws -> [String] {
        var s = Scanner(bytes: Array(data))
        s.skipWS()
        return try s.keys(path: path[...])
    }

    private struct Scanner {
        let bytes: [UInt8]
        var i = 0

        mutating func skipWS() {
            while i < bytes.count, [0x20, 0x09, 0x0A, 0x0D].contains(bytes[i]) { i += 1 }
        }

        mutating func expect(_ b: UInt8) throws {
            skipWS()
            guard i < bytes.count, bytes[i] == b else { throw ExtubationError.malformedLogic("unexpected JSON at byte \(i)") }
            i += 1
        }

        mutating func string() throws -> String {
            try expect(0x22) // "
            var out: [UInt8] = []
            while i < bytes.count, bytes[i] != 0x22 {
                if bytes[i] == 0x5C { out.append(bytes[i]); i += 1 } // keep the escape pair intact
                out.append(bytes[i]); i += 1
            }
            i += 1
            // Decode escapes properly by round-tripping through JSONDecoder.
            let quoted = [0x22] + out + [0x22]
            return try JSONDecoder().decode(String.self, from: Data(quoted))
        }

        mutating func skipValue() throws {
            skipWS()
            guard i < bytes.count else { throw ExtubationError.malformedLogic("unexpected end of JSON") }
            switch bytes[i] {
            case 0x22: _ = try string()
            case 0x7B, 0x5B: // { [
                var depth = 0
                repeat {
                    switch bytes[i] {
                    case 0x22: _ = try string(); continue
                    case 0x7B, 0x5B: depth += 1
                    case 0x7D, 0x5D: depth -= 1
                    default: break
                    }
                    i += 1
                } while depth > 0 && i < bytes.count
            default:
                while i < bytes.count, ![0x2C, 0x7D, 0x5D].contains(bytes[i]) { i += 1 } // , } ]
            }
        }

        /// At an object: walk down `path`, then return the keys of the object there.
        mutating func keys(path: ArraySlice<String>) throws -> [String] {
            try expect(0x7B)
            var found: [String] = []
            skipWS()
            if bytes[i] == 0x7D { i += 1; return found }
            while true {
                let key = try string()
                try expect(0x3A) // :
                if let head = path.first {
                    if key == head { skipWS(); return try keys(path: path.dropFirst()) }
                    try skipValue()
                } else {
                    found.append(key)
                    try skipValue()
                }
                skipWS()
                if bytes[i] == 0x2C { i += 1; continue } // ,
                try expect(0x7D)
                break
            }
            guard path.isEmpty else { throw ExtubationError.malformedLogic("key \(path.first!) not found") }
            return found
        }
    }
}
