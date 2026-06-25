import XCTest

final class CohabUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testScreenshots() throws {
        Thread.sleep(forTimeInterval: 2)

        // 1. Dashboard — empty or with household
        save("01_dashboard")

        // 2. Setup household if needed
        if app.buttons["Get started"].waitForExistence(timeout: 2) {
            app.buttons["Get started"].tap()
            Thread.sleep(forTimeInterval: 0.5)
            let fieldA = app.textFields["Partner A name"]
            if fieldA.waitForExistence(timeout: 2) {
                fieldA.tap(); fieldA.typeText("Alex")
            }
            let fieldB = app.textFields["Partner B name"]
            if fieldB.waitForExistence(timeout: 2) {
                fieldB.tap(); fieldB.typeText("Sophie")
            }
            app.navigationBars.buttons["Save"].tap()
            Thread.sleep(forTimeInterval: 1)
        }
        save("02_dashboard_household")

        // 3. Add asset sheet
        let plusBtn = app.buttons["plus"]
        if plusBtn.waitForExistence(timeout: 3) {
            plusBtn.tap()
            Thread.sleep(forTimeInterval: 0.8)
            save("03_add_asset")

            // Fill in some data
            let labelField = app.textFields["Main home"]
            if labelField.waitForExistence(timeout: 2) {
                labelField.tap(); labelField.typeText("Our home")
            }
            app.textFields["0"].firstMatch.tap()
            app.textFields["0"].firstMatch.typeText("350000")

            save("04_add_asset_filled")

            // Save asset
            app.navigationBars.buttons["Add"].tap()
            Thread.sleep(forTimeInterval: 1)
        }
        save("05_dashboard_with_asset")

        // 4. Tap asset to edit
        let assetCard = app.buttons.firstMatch
        if assetCard.waitForExistence(timeout: 2) {
            // find edit sheet by tapping the card area
            let cards = app.buttons.allElementsBoundByIndex
                .filter { $0.frame.width > 300 && $0.frame.height > 100 }
            if let card = cards.first {
                card.tap()
                Thread.sleep(forTimeInterval: 0.8)
                save("06_edit_asset")

                // Tap add contribution
                let addContrib = app.buttons.matching(
                    NSPredicate(format: "label CONTAINS 'plus.circle'")
                ).firstMatch
                if addContrib.waitForExistence(timeout: 2) {
                    addContrib.tap()
                    Thread.sleep(forTimeInterval: 0.8)
                    save("07_add_contribution")
                    app.navigationBars.buttons["Cancel"].tap()
                    Thread.sleep(forTimeInterval: 0.5)
                }
                app.navigationBars.buttons["Cancel"].tap()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }

        // 5. Calculators tab
        app.tabBars.buttons["Calculators"].tap()
        Thread.sleep(forTimeInterval: 1)
        save("08_calculators")
    }

    private func save(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/cohab_\(name).png"))
    }
}
