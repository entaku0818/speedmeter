//
//  AppOpenAdManager.swift
//  speedmeter
//
//  App Open 広告。
//
//  ⚠️ 安全上の大原則: 本アプリはGPSスピードメーターであり、運転中・計測中に
//  全画面広告を被せることは絶対にしない。表示は「アプリのコールドスタート直後」
//  に限定し、計測中(LocationManager.isTracking)なら必ずスキップする。
//  フォアグラウンド復帰では一切表示しない（運転中に戻ってきた可能性があるため）。
//

import Foundation
import GoogleMobileAds
import UIKit
import os.log

@MainActor
final class AppOpenAdManager: NSObject {
    static let shared = AppOpenAdManager()

    private let logger = OSLog(subsystem: "com.entaku.speedmeter", category: "AppOpenAd")

    /// 起動回数カウンタ。他機能とキーを共有しないこと（専用キー）
    private static let launchCountKey = "appOpenAdLaunchCount"
    /// 何回の起動に1回出すか
    private static let showEveryNLaunches = 5
    /// ロード待ちの上限（App Open広告の取得は通常1〜2秒かかる）
    private static let loadTimeout: TimeInterval = 4.0
    /// 読み込んだ広告の有効期限
    private static let adExpiration: TimeInterval = 4 * 60 * 60

    private var appOpenAd: AppOpenAd?
    private var loadTime: Date?
    private var isShowingAd = false
    /// プロセス内で1回だけ（フォアグラウンド復帰では出さない）
    private var hasAttemptedThisLaunch = false

    /// AdMobの広告ユニットID。未設定なら機能ごと無効。
    private var adUnitID: String {
        (Bundle.main.object(forInfoDictionaryKey: "AdMobAppOpenID") as? String ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// ユニットID未発行なら false。この場合プリロードもリクエストも一切走らせない。
    var isConfigured: Bool { !adUnitID.isEmpty }

    private override init() {
        super.init()
    }

    // MARK: - エントリポイント

    /// コールドスタート直後に一度だけ呼ぶ。
    /// 表示資格が無ければロードもしない（無駄打ちを避ける）。
    func showOnColdLaunchIfEligible() async {
        guard !hasAttemptedThisLaunch else { return }
        hasAttemptedThisLaunch = true

        guard isConfigured else {
            os_log("App open ad unit ID not configured; skipping", log: logger, type: .debug)
            return
        }
        guard isEligibleToShow(reason: "pre-load") else { return }
        guard consumeLaunchGate() else { return }

        await loadAd()

        // ロード待ちの数秒のあいだに計測が始まっている可能性があるので、
        // 表示直前にもう一度ガードを通す。
        guard isEligibleToShow(reason: "pre-present") else { return }

        present()
    }

    // MARK: - ガード

    /// 表示してよい状態か。ここを通らない限り絶対に表示しない。
    private func isEligibleToShow(reason: String) -> Bool {
        // 1. 課金ユーザーには出さない
        if PurchaseManager.shared.isPremium {
            os_log("Skip app open ad (%{public}@): premium user", log: logger, type: .debug, reason)
            return false
        }
        // 2. 計測中は絶対に出さない（運転中・走行中に全画面広告を被せない）
        if LocationManager.shared.isTracking {
            os_log("Skip app open ad (%{public}@): tracking in progress", log: logger, type: .debug, reason)
            return false
        }
        // 3. 同意が取れていない場合は広告をリクエストしない
        if !AdConsentManager.shared.canRequestAds {
            os_log("Skip app open ad (%{public}@): consent not obtained", log: logger, type: .debug, reason)
            return false
        }
        // 4. 多重表示防止
        if isShowingAd {
            return false
        }
        // 5. アプリがアクティブでなければ出さない
        if UIApplication.shared.applicationState != .active {
            os_log("Skip app open ad (%{public}@): app not active", log: logger, type: .debug, reason)
            return false
        }
        return true
    }

    /// 起動N回に1回だけ true を返す。専用キーのカウンタを使う。
    private func consumeLaunchGate() -> Bool {
        let defaults = UserDefaults.standard
        let count = defaults.integer(forKey: Self.launchCountKey) + 1
        defaults.set(count, forKey: Self.launchCountKey)

        let shouldShow = Self.shouldShow(atLaunchCount: count, everyN: Self.showEveryNLaunches)
        if !shouldShow {
            os_log("Skip app open ad: launch gate (%{public}d/%{public}d)",
                   log: logger, type: .debug, count % Self.showEveryNLaunches, Self.showEveryNLaunches)
        }
        return shouldShow
    }

    /// 起動N回に1回の判定（純粋関数・テスト用に切り出し）
    nonisolated static func shouldShow(atLaunchCount count: Int, everyN: Int) -> Bool {
        guard everyN > 0, count > 0 else { return false }
        return count % everyN == 0
    }

    private var isAdValid: Bool {
        guard appOpenAd != nil, let loadTime else { return false }
        return Date().timeIntervalSince(loadTime) < Self.adExpiration
    }

    // MARK: - ロード / 表示

    /// 最大 loadTimeout 秒までロードを待つ。待たずに諦めると表示率がほぼ0%になる。
    private func loadAd() async {
        if isAdValid { return }

        let unitID = adUnitID
        let start = Date()

        let loadTask = Task { () -> AppOpenAd? in
            try? await AppOpenAd.load(with: unitID, request: Request())
        }
        let timeoutTask = Task { () -> AppOpenAd? in
            try? await Task.sleep(nanoseconds: UInt64(Self.loadTimeout * 1_000_000_000))
            return nil
        }

        let ad = await withTaskGroup(of: AppOpenAd?.self) { group -> AppOpenAd? in
            group.addTask { await loadTask.value }
            group.addTask { await timeoutTask.value }
            let first = await group.next() ?? nil
            group.cancelAll()
            return first
        }

        loadTask.cancel()
        timeoutTask.cancel()

        guard let ad else {
            os_log("App open ad load failed or timed out after %{public}.1fs",
                   log: logger, type: .error, Date().timeIntervalSince(start))
            return
        }

        ad.fullScreenContentDelegate = self
        appOpenAd = ad
        loadTime = Date()
        os_log("App open ad loaded in %{public}.1fs", log: logger, type: .debug, Date().timeIntervalSince(start))
    }

    private func present() {
        guard isAdValid, let ad = appOpenAd else { return }
        guard let rootViewController = AdConsentManager.topViewController() else { return }

        isShowingAd = true
        ad.present(from: rootViewController)
    }
}

// MARK: - FullScreenContentDelegate

extension AppOpenAdManager: FullScreenContentDelegate {
    nonisolated func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        Task { @MainActor in
            self.isShowingAd = false
            self.appOpenAd = nil
            self.loadTime = nil
        }
    }

    nonisolated func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        Task { @MainActor in
            os_log("App open ad failed to present: %{public}@",
                   log: self.logger, type: .error, error.localizedDescription)
            self.isShowingAd = false
            self.appOpenAd = nil
            self.loadTime = nil
        }
    }
}
