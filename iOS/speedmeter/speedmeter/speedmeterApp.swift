//
//  speedmeterApp.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import SwiftUI
import GoogleMobileAds
import RevenueCat

@main
struct speedmeterApp: App {
    init() {
        // AdMob初期化
        MobileAds.shared.start(completionHandler: nil)

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
        }
    }
}
