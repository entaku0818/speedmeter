//
//  ATTManager.swift
//  speedmeter
//
//  Created by Claude on 2026/01/06.
//

import AppTrackingTransparency
import Combine
import GoogleMobileAds
import os.log

@MainActor
class ATTManager: ObservableObject {
    static let shared = ATTManager()

    private let logger = OSLog(subsystem: "com.entaku.speedmeter", category: "ATT")

    /// AdMobの初期化が完了し、広告をリクエストしてよい状態か
    @Published private(set) var isReady: Bool = false

    private init() {}

    /// UMP同意 → ATT許可 → AdMob初期化 の順に実行する。
    ///
    /// Googleの推奨順序。UMPの同意情報が無いまま広告をリクエストすると
    /// 規制対象地域で配信できる需要が減り、充填率が落ちる。
    func requestTrackingAuthorizationAndInitializeAds() async {
        // 1. UMP同意（EEA/UK/規制対象の米州でのみフォームが出る）
        await AdConsentManager.shared.gatherConsent()

        // 2. ATTダイアログ（iOS 14以降）
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            // 少し待ってから表示（UX向上のため / 同意フォームの解除を待つ）
            try? await Task.sleep(nanoseconds: 500_000_000)
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        // 3. 同意が取れていない場合は広告をリクエストしない
        guard AdConsentManager.shared.canRequestAds else {
            os_log("Ads not requestable: consent not obtained", log: logger, type: .info)
            return
        }

        // 4. AdMobを初期化
        await withCheckedContinuation { continuation in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }

        isReady = true

        // 5. コールドスタート時のみ App Open 広告を検討する
        //    （計測中・課金ユーザーはAppOpenAdManager側で必ず弾かれる）
        await AppOpenAdManager.shared.showOnColdLaunchIfEligible()
    }
}
