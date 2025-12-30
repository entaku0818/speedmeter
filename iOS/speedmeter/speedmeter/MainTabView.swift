//
//  MainTabView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var locationManager = LocationManager()
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var premiumSettings = PremiumSettings.shared

    private var backgroundColor: Color {
        purchaseManager.isPremium ? premiumSettings.themeColor.color : .black
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                TabView {
                    SpeedView(locationManager: locationManager)
                        .tabItem {
                            Image(systemName: "speedometer")
                            Text("Speed")
                        }

                    MapTabView(locationManager: locationManager)
                        .tabItem {
                            Image(systemName: "map")
                            Text("Map")
                        }
                }

                if !purchaseManager.isPremium {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.black)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    MainTabView()
}
