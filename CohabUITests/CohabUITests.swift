import XCTest

final class CohabUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app.launch()
    }

    func testOnboardingScreenshots() throws {
        Thread.sleep(forTimeInterval: 2)
        shot("0_intro")                          // Dark intro screen

        app.buttons["Get started"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        shot("1_purpose")                        // How will you use cohab?

        // Tap "Formal ownership record"
        app.staticTexts["Formal ownership record"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        shot("2_dissolution")                    // Add a settlement clause?

        // Tap "Yes — include it"
        app.staticTexts["Yes — include it"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        shot("3_partners")                       // Who is this between?

        // Fill in partner names + emails
        let fields = app.textFields.allElementsBoundByIndex
        if fields.count > 0 { fields[0].tap(); fields[0].typeText("Alex") }
        if fields.count > 1 { fields[1].tap(); fields[1].typeText("alex@example.com") }
        if fields.count > 2 { fields[2].tap(); fields[2].typeText("Sophie") }
        if fields.count > 3 { fields[3].tap(); fields[3].typeText("sophie@example.com") }
        app.keyboards.firstMatch.buttons["return"].tap()
        Thread.sleep(forTimeInterval: 0.3)
        shot("3_partners_filled")

        app.buttons["Continue"].tap()
        Thread.sleep(forTimeInterval: 0.6)
        shot("4_ready")                          // You're all set
    }

    private func shot(_ name: String) {
        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s)
        a.name = name; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/ob_\(name).png"))
    }
}
