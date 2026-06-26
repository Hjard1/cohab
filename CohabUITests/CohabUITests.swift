import XCTest

final class CohabUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testFullFlow() throws {
        Thread.sleep(forTimeInterval: 2)
        shot("01_intro")

        // ── Onboarding ────────────────────────────────────────────────
        app.buttons["Get started"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        shot("02_purpose")

        // Formal ownership record
        app.staticTexts["Formal ownership record"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        shot("03_dissolution")

        // Yes include it
        app.staticTexts["Yes — include it"].tap()
        Thread.sleep(forTimeInterval: 0.5)
        shot("04_partners")

        // Fill in partner names
        let fields = app.textFields.allElementsBoundByIndex
        if fields.count > 0 { fields[0].tap(); fields[0].typeText("Alex") }
        if fields.count > 2 { fields[2].tap(); fields[2].typeText("Sophie") }

        // Scroll down to see Continue
        app.swipeUp()
        Thread.sleep(forTimeInterval: 0.3)
        shot("04b_partners_filled")

        // Continue
        let cont = app.buttons["Continue"]
        if cont.waitForExistence(timeout: 3) { cont.tap() }
        Thread.sleep(forTimeInterval: 0.6)
        shot("05_ready_disclaimer")

        // Tap disclaimer checkbox
        let checkbox = app.buttons.matching(NSPredicate(format: "label CONTAINS 'understand'")).firstMatch
        if checkbox.waitForExistence(timeout: 2) {
            checkbox.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }
        shot("05b_disclaimer_checked")

        // Start tracking
        app.buttons["Start tracking"].tap()
        Thread.sleep(forTimeInterval: 1.5)
        shot("06_dashboard_empty")

        // ── Add asset ─────────────────────────────────────────────────
        let plus = app.buttons["plus"]
        if plus.waitForExistence(timeout: 3) {
            plus.tap()
            Thread.sleep(forTimeInterval: 0.8)
            shot("07_add_asset")

            // Type name
            let nameFields = app.textFields.allElementsBoundByIndex.filter { $0.placeholderValue == "Home" }
            nameFields.first?.tap()
            nameFields.first?.typeText("Our home")

            app.swipeUp()
            Thread.sleep(forTimeInterval: 0.3)
            shot("07b_add_asset_value")

            app.navigationBars.buttons["Add"].tap()
            Thread.sleep(forTimeInterval: 1)
        }
        shot("08_dashboard_with_asset")

        // ── Expand settlement breakdown ───────────────────────────────
        let showCalc = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Show calculation'")).firstMatch
        if showCalc.waitForExistence(timeout: 3) {
            showCalc.tap()
            Thread.sleep(forTimeInterval: 0.5)
            shot("09_settlement_breakdown")
        }

        // ── Calculators tab ───────────────────────────────────────────
        app.tabBars.buttons["Calculators"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        shot("10_calculators")
    }

    private func shot(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/live_\(name).png"))
    }
}
