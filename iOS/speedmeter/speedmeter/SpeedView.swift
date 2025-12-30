//
//  SpeedView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import SwiftUI
import CoreLocation

struct SpeedView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var fontSettings = FontSettings.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var premiumSettings = PremiumSettings.shared
    @State private var showingSettings = false

    private var backgroundColor: Color {
        purchaseManager.isPremium ? premiumSettings.themeColor.color : .black
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 20) {
                HStack {
                    Spacer()
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                    }
                }

                Spacer()

                // Speed display
                VStack(spacing: 8) {
                    Text(String(format: "%.0f", locationManager.speedKmh))
                        .font(fontSettings.selectedFont.font(size: 120))
                        .foregroundColor(.white)

                    Text("km/h")
                        .font(.title)
                        .foregroundColor(.gray)
                }

                Spacer()

                // Status and controls
                VStack(spacing: 16) {
                    statusView

                    Button(action: {
                        if locationManager.isTracking {
                            locationManager.stopTracking()
                        } else {
                            if locationManager.authorizationStatus == .notDetermined {
                                locationManager.requestPermission()
                            } else {
                                locationManager.startTracking()
                            }
                        }
                    }) {
                        Text(locationManager.isTracking ? "Stop" : "Start")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(width: 200, height: 50)
                            .background(locationManager.isTracking ? Color.red : Color.blue)
                            .cornerRadius(25)
                    }
                }
                .padding(.bottom, 20)
            }
        }
        .onReceive(locationManager.$authorizationStatus) { status in
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                if !locationManager.isTracking {
                    locationManager.startTracking()
                }
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(locationManager: locationManager)
        }
        .animation(.easeInOut(duration: 0.3), value: premiumSettings.themeColor)
    }

    @ViewBuilder
    private var statusView: some View {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            Text("Tap Start to begin")
                .foregroundColor(.gray)
        case .denied, .restricted:
            Text("Location access denied. Please enable in Settings.")
                .foregroundColor(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        case .authorizedWhenInUse, .authorizedAlways:
            if locationManager.isTracking {
                HStack {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                    Text("GPS Active")
                        .foregroundColor(.green)
                }
            } else {
                Text("Ready")
                    .foregroundColor(.gray)
            }
        @unknown default:
            EmptyView()
        }
    }
}

#Preview {
    SpeedView(locationManager: LocationManager())
}
