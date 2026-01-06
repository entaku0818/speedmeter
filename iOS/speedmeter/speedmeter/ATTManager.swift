//
//  ATTManager.swift
//  speedmeter
//
//  Created by Claude on 2026/01/06.
//

import AppTrackingTransparency
import GoogleMobileAds

@MainActor
class ATTManager: ObservableObject {
    static let shared = ATTManager()

    @Published private(set) var isReady: Bool = false

    private init() {}

    /// ATT許可リクエストを実行し、AdMobを初期化
    func requestTrackingAuthorizationAndInitializeAds() async {
        // ATTダイアログを表示（iOS 14以降）
        if ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
            _ = await ATTrackingManager.requestTrackingAuthorization()
        }

        // AdMobを初期化
        await withCheckedContinuation { continuation in
            MobileAds.shared.start { _ in
                continuation.resume()
            }
        }

        isReady = true
    }
}
