import XCTest

final class CaptureUITests: XCTestCase {
    func testTextCaptureAppearsOnHome() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["quick-capture"].tap()
        app.textViews["capture-text"].tap()
        app.textViews["capture-text"].typeText("Swift actors for browser networking")
        app.buttons["save-capture"].tap()

        XCTAssertTrue(app.staticTexts["Swift actors for browser networking"].waitForExistence(timeout: 3))
    }
}
