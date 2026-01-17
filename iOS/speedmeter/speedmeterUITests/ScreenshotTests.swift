//
//  ScreenshotTests.swift
//  speedmeterUITests
//
//  App Store用スクリーンショット自動撮影
//
//  実行方法:
//  xcodebuild test -project iOS/speedmeter/speedmeter.xcodeproj \
//    -scheme speedmeter -destination 'platform=iOS Simulator,name=iPhone 14 Pro Max' \
//    -only-testing:speedmeterUITests/ScreenshotTests
//

import XCTest

final class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!
    var language: String = "en"

    // スクショ保存先
    let screenshotDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Screenshots")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // スクショディレクトリ作成
        try? FileManager.default.createDirectory(at: screenshotDir, withIntermediateDirectories: true)
    }

    func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // ファイルにも保存
        let fileURL = screenshotDir.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: fileURL)
        print("📸 Screenshot saved: \(fileURL.path)")
    }

    // MARK: - English Screenshots

    @MainActor
    func testTakeEnglishScreenshots() throws {
        language = "en"
        app.launch()
        sleep(2)

        // Settings画面へ
        let settingsButton = app.buttons["gearshape.fill"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button not found")
        settingsButton.tap()
        sleep(1)

        // Screenshot Modeをタップ (スクロールして探す)
        let screenshotMode = app.staticTexts["Screenshot Mode"]
        if !screenshotMode.exists {
            app.swipeUp()
            sleep(1)
        }
        XCTAssertTrue(screenshotMode.waitForExistence(timeout: 3), "Screenshot Mode not found")
        screenshotMode.tap()
        sleep(1)

        // English選択
        let englishButton = app.buttons["English"]
        XCTAssertTrue(englishButton.waitForExistence(timeout: 3), "English button not found")
        englishButton.tap()
        sleep(1)

        // 1. Speed画面
        saveScreenshot("01_speed_\(language)")

        // 2. Map画面
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        saveScreenshot("02_map_\(language)")

        // 3. Settings (Speed tabに戻ってgear iconをタップ)
        app.tabBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        let mockSettingsButton = app.buttons["gearshape.fill"]
        XCTAssertTrue(mockSettingsButton.waitForExistence(timeout: 3), "Mock settings button not found")
        mockSettingsButton.tap()
        sleep(1)
        saveScreenshot("03_settings_\(language)")

        // 4. Paywall
        let upgradeCell = app.staticTexts["Upgrade to Pro"]
        XCTAssertTrue(upgradeCell.waitForExistence(timeout: 3), "Upgrade to Pro not found")
        upgradeCell.tap()
        sleep(1)
        saveScreenshot("04_paywall_\(language)")

        print("✅ English screenshots completed!")
        print("📁 Saved to: \(screenshotDir.path)")
    }

    // MARK: - Japanese Screenshots

    @MainActor
    func testTakeJapaneseScreenshots() throws {
        language = "ja"
        app.launch()
        sleep(2)

        // Settings画面へ
        let settingsButton = app.buttons["gearshape.fill"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5), "Settings button not found")
        settingsButton.tap()
        sleep(1)

        // Screenshot Modeをタップ
        let screenshotMode = app.staticTexts["Screenshot Mode"]
        if !screenshotMode.exists {
            app.swipeUp()
            sleep(1)
        }
        XCTAssertTrue(screenshotMode.waitForExistence(timeout: 3), "Screenshot Mode not found")
        screenshotMode.tap()
        sleep(1)

        // 日本語選択
        let japaneseButton = app.buttons["日本語"]
        XCTAssertTrue(japaneseButton.waitForExistence(timeout: 3), "Japanese button not found")
        japaneseButton.tap()
        sleep(1)

        // 1. Speed画面
        saveScreenshot("01_speed_\(language)")

        // 2. Map画面
        app.tabBars.buttons.element(boundBy: 1).tap()
        sleep(1)
        saveScreenshot("02_map_\(language)")

        // 3. Settings
        app.tabBars.buttons.element(boundBy: 0).tap()
        sleep(1)
        let mockSettingsButton = app.buttons["gearshape.fill"]
        XCTAssertTrue(mockSettingsButton.waitForExistence(timeout: 3), "Mock settings button not found")
        mockSettingsButton.tap()
        sleep(1)
        saveScreenshot("03_settings_\(language)")

        // 4. Paywall
        let upgradeCell = app.staticTexts["Proにアップグレード"]
        XCTAssertTrue(upgradeCell.waitForExistence(timeout: 3), "Upgrade to Pro (JP) not found")
        upgradeCell.tap()
        sleep(1)
        saveScreenshot("04_paywall_\(language)")

        print("✅ Japanese screenshots completed!")
        print("📁 Saved to: \(screenshotDir.path)")
    }
}
