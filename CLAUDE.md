# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the project
xcodebuild -project iOS/speedmeter/speedmeter.xcodeproj -scheme speedmeter -configuration Debug build

# Run tests
xcodebuild -project iOS/speedmeter/speedmeter.xcodeproj -scheme speedmeter test -destination 'platform=iOS Simulator,name=iPhone 16'

# Run a single test
xcodebuild -project iOS/speedmeter/speedmeter.xcodeproj -scheme speedmeter test -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:speedmeterTests/speedmeterTests/testSpeedConversion
```

## Architecture

This is a SwiftUI iOS app that displays real-time GPS speed with a digital clock-style display.

### Core Components

- **MainTabView** - Tab container with Speed and Map tabs, holds shared LocationManager
- **SpeedView** - Main speed display with Start/Stop controls
- **MapTabView** - Apple MapKit view showing current location and history pins (color-coded by speed)
- **LocationManager** - CoreLocation wrapper, publishes speed/location via @Published properties
- **LocationHistoryStore** - Singleton storing up to 1000 location records in UserDefaults
- **SettingsView** - Font selection, location history, debug features (DEBUG builds only)

### State Management

- Singletons: `LocationHistoryStore.shared`, `FontSettings.shared`
- LocationManager owned by MainTabView, passed down to child views
- Reactive updates via Combine (@Published, @ObservedObject)

### Build Configurations

- `Config/Debug.xcconfig` - Test AdMob IDs
- `Config/Release.xcconfig` - Production AdMob IDs
- Info.plist uses `$(ADMOB_APP_ID)` and `$(ADMOB_BANNER_ID)` variables

### Dependencies (Swift Package Manager)

- GoogleMobileAds - Banner ad integration via BannerAdView (UIViewRepresentable wrapper)

### Debug Features (DEBUG builds only)

- Speed simulation (Walking/Running/Cycling/Driving/Highway)
- Screenshot mode for App Store screenshots (ScreenshotMockView)

## Release Process

### App Store Release Workflow

```bash
# 1. Version Update
sed -i '' 's/MARKETING_VERSION = X\.X\.X;/MARKETING_VERSION = Y.Y.Y;/g' iOS/speedmeter/speedmeter.xcodeproj/project.pbxproj

# 2. Update Release Notes
# Edit fastlane/metadata/ja/release_notes.txt
# Edit fastlane/metadata/en-US/release_notes.txt

# 3. Archive (using xcodebuild directly, NOT fastlane gym to avoid timeout)
cd iOS/speedmeter
xcodebuild archive \
  -project speedmeter.xcodeproj \
  -scheme speedmeter \
  -configuration Release \
  -archivePath build/speedmeter.xcarchive \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=4YZQY4C47E

# 4. Export IPA
xcodebuild -exportArchive \
  -archivePath build/speedmeter.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist build/AppStoreExportOptions.plist \
  -allowProvisioningUpdates

# 5. Upload to App Store Connect
cd build/export
xcrun altool --upload-app \
  --type ios \
  --file speedmeter.ipa \
  --apiKey R2Q4FFAG8D \
  --apiIssuer 3cc1c923-009c-4963-a9db-83d030e4c4e3

# 6. Submit for Review
cd ../..
fastlane submit_build

# 7. Git Management
git add iOS/speedmeter/speedmeter.xcodeproj/project.pbxproj fastlane/metadata
git commit -m "Release vX.X.X: Update metadata and submit to App Store"
git tag vX.X.X
git push origin main && git push origin vX.X.X
```

### Important Notes

- **Use xcodebuild directly**: fastlane gym has `xcodebuild -showBuildSettings` timeout issues
- **Use DEVELOPMENT_TEAM**: Don't use CODE_SIGN_IDENTITY (causes signing conflicts)
- **Release notes required**: Must create release_notes.txt for all languages
- **Keywords max 100 chars**: Exceeding 100 characters will fail submission
- **API authentication**: App Store Connect API avoids 2FA issues

### Common Errors

- `xcodebuild -showBuildSettings timed out` → Use xcodebuild directly
- `Signing conflicts` → Use DEVELOPMENT_TEAM only, not CODE_SIGN_IDENTITY
- `whatsNew required` → Add release_notes.txt
- `Keywords too long` → Keep under 100 characters
- `Version already used` → Increment version number

### fastlane Configuration

```ruby
# Fastfile with API authentication
require 'dotenv'
Dotenv.load

default_platform(:ios)

platform :ios do
  before_all do
    app_store_connect_api_key(
      key_id: ENV["APP_STORE_CONNECT_API_KEY_KEY_ID"],
      issuer_id: ENV["APP_STORE_CONNECT_API_KEY_ISSUER_ID"],
      key_content: ENV["APP_STORE_CONNECT_API_KEY_CONTENT"]
    )
  end

  lane :submit_build do
    version_number = get_version_number(
      xcodeproj: "iOS/speedmeter/speedmeter.xcodeproj",
      target: "speedmeter"
    )

    deliver(
      skip_binary_upload: true,
      skip_app_version_update: false,
      app_version: version_number,
      skip_metadata: false,
      skip_screenshots: true,
      force: true,
      submit_for_review: true,
      automatic_release: false,
      run_precheck_before_submit: false,
      precheck_include_in_app_purchases: false,
      ignore_language_directory_validation: true,
      submission_information: {
        add_id_info_uses_idfa: true,
        export_compliance_uses_encryption: false,
        export_compliance_platform: "ios"
      }
    )
  end
end
```

## User Commands

- 「進捗どう？」と聞かれたら、完了タスク・残タスク・関連URLをまとめて報告する
- 「リリースして」「App Storeに申請して」→ Release Process を実行
