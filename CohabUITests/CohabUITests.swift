import XCTest

final class CohabUITests: XCTestCase {
    let app = XCUIApplication()
    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testAssetTypeForms() throws {
        Thread.sleep(forTimeInterval: 2)

        // Ensure household exists
        if app.buttons["Get started"].waitForExistence(timeout: 2) {
            app.buttons["Get started"].tap()
            Thread.sleep(forTimeInterval: 0.4)
            let fA = app.textFields["Partner A name"]
            if fA.waitForExistence(timeout: 2) { fA.tap(); fA.typeText("Alex") }
            let fB = app.textFields["Partner B name"]
            if fB.waitForExistence(timeout: 2) { fB.tap(); fB.typeText("Sophie") }
            app.navigationBars.buttons["Save"].tap()
            Thread.sleep(forTimeInterval: 1)
        }

        // Open add-asset sheet
        let plus = app.buttons["plus"]
        guard plus.waitForExistence(timeout: 3) else { return }
        plus.tap()
        Thread.sleep(forTimeInterval: 0.8)

        // 1. Home (default)
        save("add_home")

        // 2. Tap Car
        app.staticTexts["Car"].tap(); Thread.sleep(forTimeInterval: 0.4)
        save("add_car")

        // 3. Investment
        app.staticTexts["Investment"].tap(); Thread.sleep(forTimeInterval: 0.4)
        save("add_investment")

        // 4. Savings
        app.staticTexts["Savings"].tap(); Thread.sleep(forTimeInterval: 0.4)
        save("add_savings")

        app.navigationBars.buttons["Cancel"].tap()
    }

    private func save(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/cohab_type_\(name).png"))
    }
}
