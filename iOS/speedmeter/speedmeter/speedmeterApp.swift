//
//  speedmeterApp.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import SwiftUI
import GoogleMobileAds
import RevenueCat
import FirebaseCore
import FirebaseAnalytics
import FirebaseCrashlytics

@main
struct speedmeterApp: App {
    init() {
        // Firebase初期化
        FirebaseApp.configure()
        Analytics.logEvent(AnalyticsEventAppOpen, parameters: nil)

        // 注意: AdMob初期化はATT許可後に行う（.taskで実行）

        // RevenueCat初期化
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String,
           !apiKey.isEmpty {
            Purchases.logLevel = .debug
            Purchases.configure(withAPIKey: apiKey)
        }

        // 起動時にプレミアム状態を確認
        Task {
            await PurchaseManager.shared.checkPremiumStatus()
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .task {
                    // アプリがアクティブになってからATT許可を要求しAdMob初期化
                    await ATTManager.shared.requestTrackingAuthorizationAndInitializeAds()
                }
        }
    }
}
