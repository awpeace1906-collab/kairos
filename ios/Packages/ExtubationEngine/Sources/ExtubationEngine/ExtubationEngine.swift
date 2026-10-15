import Foundation

// Extubation decision engine — a port of extubation-engine-reference.js,
// adapted from AnesCalc's ExtubationEngine.swift. Pure: no UI, no app state,
// no network. Must give the same result as the reference for every vignette
// (Tests/ExtubationEngineTests). JS twin: web/src/lib/extubationEngine.js.

// MARK: - Answers

public struct ExtubationAnswers: Equatable {
    public var setting: String = ""
    /// checklist screen id -> checked item ids
    public var checklists: [String: Set<String>] = [:]
    /// yes_no / single_choice screen id -> answer ("yes", "no", or an option id)
    public var choices: [String: String] = [:]
    /// text_fields screen id -> field id -> text
    public var textFields: [String: [String: String]] = [:]

    public init() {}

    public func checked(_ screenId: String) -> Set<String> { checklists[screenId] ?? [] }
    public func answer(_ screenId: String) -> String? { screenId == "setting" ? setting : choices[screenId] }
}

// MARK: - Result

public struct ExtubationResult: Equatable {
    public let outcome: String
    public let outcomeClass: String
    public let chip: String
    public let title: String
    public let recommendation: String
    public let riskCount: Int?
    public let why: [String]
    public let alerts: [AlertResult]
    public let sources: [String]
    public let screensShown: [String]
}

public struct AlertResult: Equatable {
    public let id: String
    public let level: String
    public let text: String
    public let requiresAck: Bool
}

// MARK: - Engine

public func extubationEvaluate(logic: ExtubationLogic, answers: ExtubationAnswers) throws -> ExtubationResult {
    let screensById = Dictionary(uniqueKeysWithValues: logic.screens.map { ($0.id, $0) })
    let track = answers.setting

    func checked(_ id: String) -> Set<String> { answers.checked(id) }
    func items(_ id: String) -> [ChecklistItem] { screensById[id]?.items ?? [] }

    func cond(_ c: Condition?) throws -> Bool {
        guard let c else { return true }
        if c.always == true { return true }
        if let countId = c.count {
            let n = checked(countId).count
            if let eq = c.eq { return eq.matchesInt(n) }
            if let gte = c.gte { return n >= gte }
            throw ExtubationError.unknownCondition
        }
        if let answerId = c.answer, let eq = c.eq { return eq.matchesString(answers.answer(answerId)) }
        if let screenId = c.anyUnchecked {
            let checkedIds = checked(screenId)
            return items(screenId).contains { item in
                guard !checkedIds.contains(item.id) else { return false }
                if c.hardOnly == true { return item.hard == true }
                if c.softOnly == true { return item.hard == false }
                return true
            }
        }
        throw ExtubationError.unknownCondition
    }

    var shown: [String] = []
    var outcome: String?
    for step in logic.flow[track] ?? [] {
        guard let screen = screensById[step.at] else { continue }
        if let showIf = screen.showIf, try !cond(showIf) { continue }
        shown.append(screen.id)
        if let stopIf = step.stopIf, try cond(stopIf) { outcome = step.outcome; break }
    }
    if outcome == nil {
        outcome = try logic.outcomeRules.first { try $0.track == track && cond($0.when) }?.outcome
    }
    guard let outcomeId = outcome, let oc = logic.outcomes[outcomeId] else {
        throw ExtubationError.noOutcome(track: track)
    }
    let isStop = oc.class == "stop"

    func labelsOf(_ id: String, _ pred: (ChecklistItem) -> Bool) -> [String] { items(id).filter(pred).map(\.label) }
    var why: [String] = []
    if let fixed = oc.why.fixed { why = fixed }
    if let id = oc.why.checked { why = labelsOf(id) { checked(id).contains($0.id) } }
    if let id = oc.why.uncheckedHard {
        why = labelsOf(id) { $0.hard == true && !checked(id).contains($0.id) }.map { (oc.why.prefix ?? "") + $0 }
    }

    let riskCount = track == "icu" ? checked("icu_reint").count : nil

    var alerts: [AlertResult] = []
    if !isStop {
        let matching = try logic.alerts.entries.filter { try $0.def.tracks.contains(track) && cond($0.def.when) }
        let ordered = matching.filter { $0.def.level == "red" } + matching.filter { $0.def.level == "amber" }
        for entry in ordered {
            var text = entry.def.text
            if let spec = entry.def.items, let sid = spec.screenId {
                let soft = spec.mode == "uncheckedSoft"
                let labels = items(sid)
                    .filter { !checked(sid).contains($0.id) && (soft ? $0.hard == false : true) }
                    .map { $0.label.lowercased() }
                text = text.replacingOccurrences(of: "{items}", with: labels.joined(separator: "; "))
            }
            alerts.append(AlertResult(id: entry.id, level: entry.def.level, text: text, requiresAck: entry.def.requiresAck ?? false))
        }
    }

    var srcKeys: [String] = []
    for k in oc.sources + alerts.flatMap({ logic.alerts.sources(for: $0.id) }) where !srcKeys.contains(k) { srcKeys.append(k) }

    // JS String(null) is "null"; no current chip with {count} can see a nil count.
    let chip = oc.chip.replacingOccurrences(of: "{count}", with: riskCount.map(String.init) ?? "null")
    return ExtubationResult(
        outcome: outcomeId, outcomeClass: oc.class, chip: chip, title: oc.title,
        recommendation: logic.ui.recommendationPrefix + " " + oc.text, riskCount: riskCount,
        why: why, alerts: alerts, sources: srcKeys, screensShown: shown)
}

// MARK: - UI helpers (not part of the reference engine; no clinical rules of their own)

/// The screen a requiresAck alert belongs to: the screen id its `when` names.
/// Null for `always` alerts. Same as alertScreenId() in the JS engine.
public func extubationAlertOwnerScreenId(_ def: AlertDef) -> String? {
    def.when.anyUnchecked ?? def.when.answer ?? def.when.count
}

/// The item ids an alert with an `items` spec currently lists; drives "a new
/// item appeared, so clear the acknowledgment". Mirrors the {items} filter.
public func extubationAlertItemIds(logic: ExtubationLogic, answers: ExtubationAnswers, alertId: String) -> Set<String> {
    guard let def = logic.alerts[alertId], let spec = def.items, let sid = spec.screenId else { return [] }
    let soft = spec.mode == "uncheckedSoft"
    let checkedIds = answers.checked(sid)
    return Set((logic.screen(sid)?.items ?? []).filter { !checkedIds.contains($0.id) && (soft ? $0.hard == false : true) }.map(\.id))
}
