import XCTest

final class LanguageSpeakingTrainerUITests: XCTestCase {
    func testHappyPath_chooseTopic_start_end() {
        // Scenario mapping (for spec coverage):
        // @HO-001 @SE-001

        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["RESET_STATE"] = "1"
        app.launch()

        // First launch shows Settings instead of a dedicated onboarding screen.
        // If it appears, dismiss it deterministically.
        let doneButton = app.buttons["settings.done"]
        if doneButton.waitForExistence(timeout: 5) {
            doneButton.tap()
        }

        XCTAssertTrue(app.buttons["home.topic.friends"].waitForExistence(timeout: 5))
        app.buttons["home.topic.friends"].tap()

        XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5))
        app.buttons["home.start"].tap()

        XCTAssertTrue(app.staticTexts["session.topic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["session.end"].waitForExistence(timeout: 5))
        app.buttons["session.end"].tap()

        // Back on Home
        XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5))
    }
}
