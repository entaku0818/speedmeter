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

    /// 本番のユニットIDが未設定なら App Open 広告は完全に無効になること。
    @MainActor
    @Test func disabledWhenAdUnitIDIsMissing() async throws {
        // Debug構成ではGoogleのテストIDが入っているので有効になる。
        // ここではフラグがInfo.plistの値と一致していることだけを確認する。
        let configuredID = (Bundle.main.object(forInfoDictionaryKey: "AdMobAppOpenID") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        #expect(AppOpenAdManager.shared.isConfigured == !configuredID.isEmpty)
    }
}
