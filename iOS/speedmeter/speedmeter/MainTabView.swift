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

    var body: some View {
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
            }
        }
    }
}

#Preview {
    MainTabView()
}
