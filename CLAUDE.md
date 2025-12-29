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
