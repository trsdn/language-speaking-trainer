import XCTest

final class LanguageSpeakingTrainerUITests: XCTestCase {
    func testHappyPath_onboarding_chooseTopic_start_end() {
        // Scenario mapping (for spec coverage):
        // @ON-001 @HO-001 @SE-001

        let app = XCUIApplication()
        app.launchEnvironment["UITESTING"] = "1"
        app.launchEnvironment["RESET_STATE"] = "1"
        app.launch()

        XCTAssertTrue(app.buttons["onboarding.continue"].waitForExistence(timeout: 5))
        app.buttons["onboarding.continue"].tap()

        XCTAssertTrue(app.buttons["home.topic.animals"].waitForExistence(timeout: 5))
        app.buttons["home.topic.animals"].tap()

        XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5))
        app.buttons["home.start"].tap()

        XCTAssertTrue(app.staticTexts["session.topic"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["session.end"].waitForExistence(timeout: 5))
        app.buttons["session.end"].tap()

        // Back on Home
        XCTAssertTrue(app.buttons["home.start"].waitForExistence(timeout: 5))
    }
}
