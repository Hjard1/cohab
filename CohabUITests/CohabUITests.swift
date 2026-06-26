import XCTest

final class CohabUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testSettlementBreakdown() throws {
        Thread.sleep(forTimeInterval: 2)

        // ── Onboarding ────────────────────────────────────────────────
        if app.buttons["Get started"].waitForExistence(timeout: 3) {
            app.buttons["Get started"].tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Purpose: tap "Formal ownership record"
            app.staticTexts["Formal ownership record"].tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Dissolution: tap "Yes — include it"
            app.staticTexts["Yes — include it"].tap()
            Thread.sleep(forTimeInterval: 0.5)

            // Partners
            let fields = app.textFields.allElementsBoundByIndex
            if fields.count > 0 { fields[0].tap(); fields[0].typeText("Alex") }
            if fields.count > 1 { fields[1].tap(); fields[1].typeText("alex@example.com") }
            if fields.count > 2 { fields[2].tap(); fields[2].typeText("Sophie") }
            if fields.count > 3 { fields[3].tap(); fields[3].typeText("sophie@example.com") }
            app.buttons["Continue"].tap()
            Thread.sleep(forTimeInterval: 0.6)

            // Ready
            app.buttons["Start tracking"].tap()
            Thread.sleep(forTimeInterval: 1)
        }

        shot("01_dashboard_empty")

        // ── Add asset ─────────────────────────────────────────────────
        let plus = app.buttons["plus"]
        if plus.waitForExistence(timeout: 3) {
            plus.tap()
            Thread.sleep(forTimeInterval: 0.8)

            // Name
            let labelField = app.textFields.element(matching: .textField, identifier: "")
                .firstMatch
            if labelField.waitForExistence(timeout: 2) {
                let nameField = app.textFields.allElementsBoundByIndex.first(where: {
                    $0.placeholderValue == "Home"
                })
                nameField?.tap()
                nameField?.typeText("Our home")
            }

            // Value
            let valueFields = app.textFields.allElementsBoundByIndex.filter {
                $0.placeholderValue == "350,000"
            }
            valueFields.first?.tap()
            valueFields.first?.typeText("450000")

            // Loan
            let loanFields = app.textFields.allElementsBoundByIndex.filter {
                $0.placeholderValue == "0" || $0.value as? String == ""
            }
            // tap the second numeric field (loan)
            let allNumeric = app.textFields.allElementsBoundByIndex
            for f in allNumeric where f.placeholderValue == "0" {
                f.tap(); f.typeText("300000")
                break
            }

            shot("02_add_asset_filled")
            app.navigationBars.buttons["Add"].tap()
            Thread.sleep(forTimeInterval: 1)
        }

        shot("03_dashboard_with_asset")

        // ── Expand settlement breakdown ───────────────────────────────
        let showCalc = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Show calculation'")).firstMatch
        if showCalc.waitForExistence(timeout: 3) {
            showCalc.tap()
            Thread.sleep(forTimeInterval: 0.5)
            shot("04_settlement_breakdown_expanded")
        }
    }

    private func shot(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/settle_\(name).png"))
    }
}
