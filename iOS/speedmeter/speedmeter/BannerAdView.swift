//
//  BannerAdView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    private var adUnitID: String {
        Bundle.main.object(forInfoDictionaryKey: "AdMobBannerID") as? String ?? ""
    }

    func makeUIView(context: Context) -> BannerView {
        let bannerView = BannerView(adSize: AdSizeBanner)
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?.rootViewController
        bannerView.load(Request())
        return bannerView
    }

    func updateUIView(_ uiView: BannerView, context: Context) {}
}

#Preview {
    BannerAdView()
        .frame(height: 50)
}
