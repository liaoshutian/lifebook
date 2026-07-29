import XCTest

final class LifeBookUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-ui-testing")
        app.launch()
    }

    func testMainTabsAndAIAssistantAreReachable() {
        XCTAssertTrue(app.tabBars.buttons["日历"].exists)
        XCTAssertTrue(app.tabBars.buttons["分析"].exists)
        XCTAssertTrue(app.tabBars.buttons["设置"].exists)

        app.tabBars.buttons["分析"].tap()
        XCTAssertTrue(app.navigationBars["分析"].waitForExistence(timeout: 2))
        app.navigationBars["分析"].buttons["AI 助理"].tap()
        XCTAssertTrue(app.navigationBars["AI 助理"].waitForExistence(timeout: 2))
        XCTAssertTrue(app.switches["我同意本次发送这些记录"].exists)
    }

    func testQuickOccurrenceRecordAppearsOnToday() {
        app.buttons["记一笔"].firstMatch.tap()
        XCTAssertTrue(app.navigationBars["记一笔"].waitForExistence(timeout: 2))

        app.buttons["理发"].tap()

        XCTAssertTrue(app.staticTexts["理发"].waitForExistence(timeout: 2))
    }

    func testCreateCustomEventThenQuickRecordIt() {
        app.tabBars.buttons["设置"].tap()
        app.buttons["自定义事件"].tap()
        XCTAssertTrue(app.navigationBars["事件管理"].waitForExistence(timeout: 2))

        app.navigationBars["事件管理"].buttons["添加事件"].tap()
        XCTAssertTrue(app.navigationBars["添加事件"].waitForExistence(timeout: 2))
        app.textFields["名称"].tap()
        app.textFields["名称"].typeText("冥想")
        app.navigationBars["添加事件"].buttons["保存"].tap()

        XCTAssertTrue(app.staticTexts["冥想"].waitForExistence(timeout: 2))
        app.tabBars.buttons["日历"].tap()
        app.buttons["记一笔"].firstMatch.tap()
        XCTAssertTrue(app.buttons["冥想"].waitForExistence(timeout: 2))
        app.buttons["冥想"].tap()
        XCTAssertTrue(app.staticTexts["冥想"].waitForExistence(timeout: 2))
    }

    func testEventStreamModeCanBeSelected() {
        app.segmentedControls.buttons["事件"].tap()
        XCTAssertTrue(app.staticTexts["还没有记录"].waitForExistence(timeout: 2))
    }
}
