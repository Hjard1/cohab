import XCTest

final class CohabUITests: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testScreenshots() throws {
        // 1. Dashboard (with household already set up via SwiftData)
        Thread.sleep(forTimeInterval: 2)
        saveScreenshot("01_dashboard")

        // 2. Navigate to Calculators tab
        let calcTab = app.tabBars.buttons["Calculators"]
        XCTAssertTrue(calcTab.waitForExistence(timeout: 5))
        calcTab.tap()
        Thread.sleep(forTimeInterval: 1)
        saveScreenshot("02_calculators")

        // 3. Ownership share calculator
        let ownershipCell = app.staticTexts["Ownership share"]
        XCTAssertTrue(ownershipCell.waitForExistence(timeout: 5))
        ownershipCell.tap()
        Thread.sleep(forTimeInterval: 1)
        saveScreenshot("03_ownership_calculator")

        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // 4. Expense split calculator
        let expenseCell = app.staticTexts["Expense split"]
        XCTAssertTrue(expenseCell.waitForExistence(timeout: 5))
        expenseCell.tap()
        Thread.sleep(forTimeInterval: 1)
        saveScreenshot("04_expense_split")

        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        Thread.sleep(forTimeInterval: 0.5)

        // 5. Rebalance calculator
        let rebalanceCell = app.staticTexts["Rebalance ownership"]
        XCTAssertTrue(rebalanceCell.waitForExistence(timeout: 5))
        rebalanceCell.tap()
        Thread.sleep(forTimeInterval: 1)
        saveScreenshot("05_rebalance")
    }

    private func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also write directly to /tmp for easy retrieval
        let data = screenshot.pngRepresentation
        let url = URL(fileURLWithPath: "/tmp/cohab_\(name).png")
        try? data.write(to: url)
    }
}
