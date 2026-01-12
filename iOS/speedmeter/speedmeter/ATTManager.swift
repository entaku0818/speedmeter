//
//  ATTManager.swift
//  speedmeter
//
//  Created by Claude on 2026/01/06.
//

import AppTrackingTransparency
import Combine
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
            // 1秒待ってから表示（UX向上のため）
            try? await Task.sleep(nanoseconds: 1_000_000_000)
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
