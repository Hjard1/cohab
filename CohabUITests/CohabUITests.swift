import XCTest

final class CohabUITests: XCTestCase {
    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        // Launch with argument to skip onboarding and show design mockups
        app.launchArguments = ["--design-preview"]
        app.launch()
    }

    func testDesignDirections() throws {
        Thread.sleep(forTimeInterval: 2)

        // The app will show current state. Take screenshots of each direction
        // by injecting the views directly via the preview system.
        // Instead: build separate targets and screenshot.
        // For now, just screenshot what's on screen.

        let s = XCUIScreen.main.screenshot()
        let a = XCTAttachment(screenshot: s); a.name = "current"; a.lifetime = .keepAlways; add(a)
        try? s.pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/design_current.png"))
    }
}
