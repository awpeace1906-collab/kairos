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
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }

        // Bazett(400, 80) ≈ 462 ms.
        XCTAssertTrue(text(containing: "462").waitForExistence(timeout: 5))
    }

    /// Home → Drug & Dosing → peds epinephrine: enter a weight, confirm a live
    /// dose + the zone bar render (the dual-mode rule).
    func testDrugCardDualModeFlow() {
        openSection("drug-dosing")
        let epiRow = app.buttons["row-peds-epinephrine-arrest"].firstMatch
        XCTAssertTrue(epiRow.waitForExistence(timeout: 5))
        epiRow.tap()

        let weight = app.textFields["drug-weight"].firstMatch
        XCTAssertTrue(weight.waitForExistence(timeout: 5))
        weight.tap(); weight.typeText("14.3")
        if app.buttons["Done"].exists { app.buttons["Done"].tap() }

        // 14.3 kg × 0.01 mg/kg = 0.143 mg, Zone 4 (Violet).
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

        let handChoice = app.buttons["tree-choice-hand"].firstMatch
        XCTAssertTrue(handChoice.waitForExistence(timeout: 5))
        handChoice.tap()

        XCTAssertTrue(app.staticTexts["tree-end"].waitForExistence(timeout: 5))
        XCTAssertTrue(text(containing: "tendon and digital-nerve function").exists)

        app.buttons["‹ Back"].firstMatch.tap()
        XCTAssertTrue(app.buttons["tree-choice-hand"].waitForExistence(timeout: 5))
    }
}
