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

    func testURLCaptureCanBeSearchedAndAssignedToNewContext() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()

        app.buttons["quick-capture"].tap()
        app.buttons["URL"].tap()
        app.textFields["capture-url"].tap()
        app.textFields["capture-url"].typeText("example.com/reference")
        app.buttons["save-capture"].tap()
        XCTAssertTrue(app.staticTexts["example.com"].waitForExistence(timeout: 3))

        app.buttons["Search"].tap()
        app.searchFields.firstMatch.tap()
        app.searchFields.firstMatch.typeText("reference")
        XCTAssertTrue(app.staticTexts["example.com"].waitForExistence(timeout: 3))
        app.staticTexts["example.com"].tap()

        app.buttons["New Context"].tap()
        app.textFields["Context name"].typeText("Reading")
        app.buttons["Create"].tap()
        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 3))
    }
}
