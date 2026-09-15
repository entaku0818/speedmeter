//
//  AppOpenAdGateTests.swift
//  speedmeterTests
//
//  App Open 広告の表示ゲートのテスト。
//

import Foundation
import Testing
@testable import speedmeter

struct AppOpenAdGateTests {

    @Test func showsOnlyEveryNthLaunch() async throws {
        let shown = (1...15).filter { AppOpenAdManager.shouldShow(atLaunchCount: $0, everyN: 5) }
        #expect(shown == [5, 10, 15])
    }

    @Test func doesNotShowOnFirstLaunch() async throws {
        #expect(AppOpenAdManager.shouldShow(atLaunchCount: 1, everyN: 5) == false)
    }

    @Test func handlesInvalidCounters() async throws {
        #expect(AppOpenAdManager.shouldShow(atLaunchCount: 0, everyN: 5) == false)
        #expect(AppOpenAdManager.shouldShow(atLaunchCount: -3, everyN: 5) == false)
        #expect(AppOpenAdManager.shouldShow(atLaunchCount: 5, everyN: 0) == false)
    }

    /// isConfigured が Info.plist の値と一致すること（未設定なら完全に無効）。
    @MainActor
    @Test func isConfiguredMatchesInfoPlist() async throws {
        #expect(AppOpenAdManager.shared.isConfigured == !Self.configuredAdUnitID.isEmpty)
    }

    /// ビルド構成に対応した広告ユニットIDが実際に埋め込まれていること。
    /// Release では本番IDが入り、Googleのテスト用publisher IDが残っていてはいけない。
    @MainActor
    @Test func adUnitIDMatchesBuildConfiguration() async throws {
        let unitID = Self.configuredAdUnitID
        #expect(AppOpenAdManager.shared.isConfigured == true)

        #if DEBUG
        #expect(unitID == "ca-app-pub-3940256099942544/5575463023")
        #else
        #expect(unitID == "ca-app-pub-3484697221349891/9775794492")
        #expect(unitID.contains("3940256099942544") == false)
        #endif
    }

    private static var configuredAdUnitID: String {
        let value = Bundle.main.object(forInfoDictionaryKey: "AdMobAppOpenID") as? String
        return (value ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
