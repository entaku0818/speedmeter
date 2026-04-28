//
//  ScreenshotTests.swift
//  speedmeterUITests
//
//  App Store用スクリーンショット自動撮影
//
//  実行方法:
//  xcodebuild test -project iOS/speedmeter/speedmeter.xcodeproj \
//    -scheme speedmeter -destination 'platform=iOS Simulator,name=iPhone 17,OS=26.1' \
//    -only-testing:speedmeterUITests/ScreenshotTests
//

import XCTest

final class ScreenshotTests: XCTestCase {
    var app: XCUIApplication!
    var language: String = "en"

    let screenshotDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Screenshots")

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-UITestScreenshotMode"]
        try? FileManager.default.createDirectory(at: screenshotDir, withIntermediateDirectories: true)
    }

    func saveScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let fileURL = screenshotDir.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: fileURL)
        print("📸 Screenshot saved: \(fileURL.path)")
    }

    func tapToNextScreen() {
        let center = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
        center.tap()
        sleep(1)
    }

    func selectLanguage(_ languageButton: String) throws {
        app.launch()
        sleep(2)

        let langButton = app.buttons[languageButton]
        XCTAssertTrue(langButton.waitForExistence(timeout: 5), "\(languageButton) button not found")
        langButton.tap()
        sleep(1)
    }

    // MARK: - English Screenshots

    @MainActor
    func testTakeEnglishScreenshots() throws {
        language = "en"
        try selectLanguage("English")

        // Screen 1: Speed + Stats bar
        saveScreenshot("01_speed_\(language)")

        // Screen 2: Stats detail
        tapToNextScreen()
        saveScreenshot("02_stats_\(language)")

        // Screen 3: Map
        tapToNextScreen()
        saveScreenshot("03_map_\(language)")

        // Screen 4: Export
        tapToNextScreen()
        saveScreenshot("04_export_\(language)")

        print("✅ English screenshots completed!")
        print("📁 Saved to: \(screenshotDir.path)")
    }

    // MARK: - Japanese Screenshots

    @MainActor
    func testTakeJapaneseScreenshots() throws {
        language = "ja"
        try selectLanguage("日本語")

        // Screen 1: Speed + Stats bar
        saveScreenshot("01_speed_\(language)")

        // Screen 2: Stats detail
        tapToNextScreen()
        saveScreenshot("02_stats_\(language)")

        // Screen 3: Map
        tapToNextScreen()
        saveScreenshot("03_map_\(language)")

        // Screen 4: Export
        tapToNextScreen()
        saveScreenshot("04_export_\(language)")

        print("✅ Japanese screenshots completed!")
        print("📁 Saved to: \(screenshotDir.path)")
    }
}
