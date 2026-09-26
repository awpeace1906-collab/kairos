import XCTest

/// Drives the real app through the UI — the iOS counterpart to the browser
/// click-throughs done for the web client. Verifies that taps, text entry, the
/// segmented Picker, and the procedure tree walker actually work on-device.
///
/// NOTE: the "Jump to a section" tiles sit below the fold in a lazy List, so a
/// section is opened via `openSection(_:)`, which scrolls the tile into view
/// first. `testProcedureTreeWalker` is the canary — it opens the first
/// (always-rendered) tile and exercises navigation + the walker + Back.
final class KairosUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-kairos.onboarding.seen", "1"]   // skip the first-run sheet
        app.launch()
    }

    /// Scroll the "Jump to a section" tile for `id` into view, then tap it.
    private func openSection(_ id: String) {
        let tile = app.buttons["section-tile-\(id)"].firstMatch
        var tries = 0
        while !tile.exists && tries < 10 {
            app.swipeUp()
            tries += 1
        }
        XCTAssertTrue(tile.waitForExistence(timeout: 3), "section tile '\(id)' never appeared")
        tile.tap()
    }

    private func text(containing needle: String) -> XCUIElement {
        app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", needle)).firstMatch
    }

    /// Home → Calculators → HEART Score: pick the top option in every item and
    /// confirm a score + "High risk" band appears.
    func testAdditiveCalculatorFlow() {
        openSection("calculators")
        XCTAssertTrue(app.navigationBars["Calculators"].waitForExistence(timeout: 5))

        let heartRow = app.buttons["row-heart-score"].firstMatch
        XCTAssertTrue(heartRow.waitForExistence(timeout: 5))
        heartRow.tap()

        for key in ["history", "ecg", "age", "riskFactors", "troponin"] {
            let opt = app.buttons["opt-\(key)-2"].firstMatch
            XCTAssertTrue(opt.waitForExistence(timeout: 5), "missing option opt-\(key)-2")
            opt.tap()
        }

        XCTAssertTrue(text(containing: "Score 10").waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "High risk").exists)
    }

    /// Home → Calculators → Corrected QT: type QT + HR, confirm the Bazett value.
    func testFormulaCalculatorFlow() {
        openSection("calculators")
        let qtcRow = app.buttons["row-qtc"].firstMatch
        XCTAssertTrue(qtcRow.waitForExistence(timeout: 5))
        qtcRow.tap()

        let qt = app.textFields["field-Measured QT interval"].firstMatch
        XCTAssertTrue(qt.waitForExistence(timeout: 5))
        qt.tap(); qt.typeText("400")

        let hr = app.textFields["field-Heart rate"].firstMatch
        hr.tap(); hr.typeText("80")
        // dismiss the keyboard so the result row is on screen
        let done = app.buttons["Done"].firstMatch
        if done.exists { done.tap() }

        // Bazett(400, 80) ≈ 462 ms.
        XCTAssertTrue(text(containing: "462").waitForExistence(timeout: 5))
    }

    /// Home → Drug & Dosing → peds epinephrine: enter a weight, confirm a live
    /// dose + the zone bar render (the dual-mode rule).
    func testDrugCardDualModeFlow() {
        openSection("drug-dosing")
        // "Weight/Age-Based Resuscitation Dosing" now sits below the 10 merged
        // perioperative categories (2026-09-04 category cleanup), so the row
        // needs the same scroll-and-retry openSection() uses for home tiles.
        let epiRow = app.buttons["row-peds-epinephrine-arrest"].firstMatch
        var tries = 0
        while !epiRow.exists && tries < 15 {
            app.swipeUp()
            tries += 1
        }
        XCTAssertTrue(epiRow.waitForExistence(timeout: 5))
        epiRow.tap()

        let weight = app.textFields["drug-weight"].firstMatch
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        weight.tap(); weight.typeText("14.3")
        let done = app.buttons["Done"].firstMatch
        if done.exists { done.tap() }

        // 14.3 kg × 0.01 mg/kg = 0.143 mg, Zone 4 (Denim, since the 2026-09-04
        // weight-zone recolour — Dove-Umber, not Broselow).
        XCTAssertTrue(text(containing: "0.143").waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "Zone 4").exists)
    }

    /// Home → Procedures → Laceration Repair: walk the decision tree.
    /// The canary test — Procedures is the first, always-rendered tile.
    func testProcedureTreeWalker() {
        openSection("procedures")
        let lacRow = app.buttons["row-laceration-repair"].firstMatch
        XCTAssertTrue(lacRow.waitForExistence(timeout: 5))
        lacRow.tap()

        // v3 added an upstream triage question, so "start" no longer leads
        // straight to "Hand" — go via "Neither — select body region" first.
        let regionChoice = app.buttons["tree-choice-region"].firstMatch
        XCTAssertTrue(regionChoice.waitForExistence(timeout: 5))
        regionChoice.tap()

        let handChoice = app.buttons["tree-choice-hand"].firstMatch
        XCTAssertTrue(handChoice.waitForExistence(timeout: 5))
        handChoice.tap()

        XCTAssertTrue(app.staticTexts["tree-end"].waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "tendon and digital-nerve function").exists)

        app.buttons["‹ Back"].firstMatch.tap()
        XCTAssertTrue(app.buttons["tree-choice-hand"].waitForExistence(timeout: 5))
    }

    /// Home → Calculators → EKG Axis Interpreter: Machine (P-R-T) opens by
    /// default; a pasted machine header fills the fields and reads marked LAD;
    /// Quadrant I+ / aVF− offers the one-tap jump to 3-Lead.
    private func openAxisTool() {
        openSection("calculators")
        let row = app.buttons["row-ekg-axis-interpreter"].firstMatch
        // Give the list a moment to render before swiping: the row sits near
        // the top (Cardiovascular), and an immediate fling scrolls past it.
        var tries = 0
        while !row.waitForExistence(timeout: 2) && tries < 12 { app.swipeUp(velocity: .slow); tries += 1 }
        XCTAssertTrue(row.exists)
        row.tap()
    }

    func testAxisToolFlow() {
        openAxisTool()

        let machine = app.buttons["axis-mode-prt"].firstMatch
        XCTAssertTrue(machine.waitForExistence(timeout: 5))
        XCTAssertTrue(machine.isSelected, "Machine (P-R-T) must be the default mode")

        let paste = app.textFields["axis-paste"].firstMatch
        paste.tap()
        paste.typeText("QRS duration 88 ms P-R-T axes 54 -60 40")
        XCTAssertTrue(text(containing: "Left axis deviation").waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "−60°").exists)
        let shot1 = XCTAttachment(screenshot: app.screenshot()); shot1.name = "axis-machine"; shot1.lifetime = .keepAlways; add(shot1)
        app.swipeUp()
        let shot2 = XCTAttachment(screenshot: app.screenshot()); shot2.name = "axis-machine-lower"; shot2.lifetime = .keepAlways; add(shot2)
        app.swipeDown(); app.swipeDown()

        app.buttons["axis-mode-quadrant"].firstMatch.tap()
        app.buttons["Lead I +"].firstMatch.tap()
        app.buttons["Lead aVF −"].firstMatch.tap()
        let jump = app.buttons["axis-add-lead-ii"].firstMatch
        XCTAssertTrue(jump.waitForExistence(timeout: 5))
        let shot3 = XCTAttachment(screenshot: app.screenshot()); shot3.name = "axis-quadrant"; shot3.lifetime = .keepAlways; add(shot3)
        jump.tap()
        XCTAssertTrue(app.buttons["axis-mode-three_lead"].firstMatch.isSelected)
        app.buttons["Lead II −"].firstMatch.tap()
        XCTAssertTrue(text(containing: "−89°").waitForExistence(timeout: 5))
    }

    /// The iPhone decimal pad has no minus key. Type on the real keypad, then
    /// use the keyboard bar's ± to go negative and its checkmark to dismiss.
    func testAxisSignKeyOnKeypad() {
        openAxisTool()
        let field = app.textFields["QRS"].firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        let old = (field.value as? String) ?? ""
        if !old.isEmpty { field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count)) }

        XCTAssertTrue(app.keys["6"].waitForExistence(timeout: 5), "decimal keypad not shown")
        XCTAssertFalse(app.keys["-"].exists, "decimal keypad unexpectedly has a minus key")
        field.typeText("60")

        let sign = app.buttons["axis-kb-sign"].firstMatch
        XCTAssertTrue(sign.waitForExistence(timeout: 3), "keyboard bar ± missing")
        sign.tap()
        XCTAssertEqual(field.value as? String, "-60")
        XCTAssertTrue(text(containing: "−60°").waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot()); shot.name = "axis-keypad-sign"; shot.lifetime = .keepAlways; add(shot)

        sign.tap()
        XCTAssertEqual(field.value as? String, "60")

        app.buttons["axis-kb-done"].firstMatch.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForNonExistence(timeout: 3), "keyboard did not dismiss")
    }
}
