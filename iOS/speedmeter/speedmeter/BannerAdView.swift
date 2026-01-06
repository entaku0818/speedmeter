//
//  BannerAdView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    @ObservedObject private var attManager = ATTManager.shared

    private var adUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdMobBannerID") as? String ?? ""
    }

    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .clear
        return containerView
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        // AdMobが初期化されるまで広告をロードしない
        guard attManager.isReady else { return }

        // 既にバナーが追加されている場合はスキップ
        if uiView.subviews.contains(where: { $0 is BannerView }) {
            return
        }

        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController

        bannerView.translatesAutoresizingMaskIntoConstraints = false
        uiView.addSubview(bannerView)

        NSLayoutConstraint.activate([
            bannerView.centerXAnchor.constraint(equalTo: uiView.centerXAnchor),
            bannerView.centerYAnchor.constraint(equalTo: uiView.centerYAnchor)
        ])

        bannerView.load(Request())
    }
}

#Preview {
    BannerAdView()
        .frame(height: 50)
}
