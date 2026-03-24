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
    @ObservedObject private var speedUnitSettings = SpeedUnitSettings.shared
    @State private var showingSettings = false

    private var backgroundColor: Color {
        purchaseManager.isPremium ? premiumSettings.themeColor.color : .black
    }

    // 現在速度を選択単位に変換
    private var displaySpeed: Double {
        speedUnitSettings.unit.convert(locationManager.speedKmh)
    }

    // 統計値を選択単位に変換
    private var displayMax: Double {
        speedUnitSettings.unit.convert(locationManager.maxSpeedKmh)
    }

    private var displayAverage: Double {
        speedUnitSettings.unit.convert(locationManager.averageSpeedKmh)
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

                // メイン速度表示
                VStack(spacing: 8) {
                    Text(String(format: "%.0f", displaySpeed))
                        .font(fontSettings.selectedFont.font(size: 120))
                        .foregroundColor(.white)
                        .contentTransition(.numericText())
                        .animation(.easeInOut(duration: 0.2), value: displaySpeed)

                    Text(speedUnitSettings.unit.displayName)
                        .font(.title)
                        .foregroundColor(.gray)
                }

                // ② 速度統計カード（トラッキング中または統計データあり）
                if locationManager.isTracking || locationManager.maxSpeedKmh > 0 {
                    HStack(spacing: 16) {
                        SpeedStatCard(
                            label: "AVG",
                            value: String(format: "%.0f", displayAverage),
                            unit: speedUnitSettings.unit.displayName,
                            color: .blue
                        )
                        SpeedStatCard(
                            label: "MAX",
                            value: String(format: "%.0f", displayMax),
                            unit: speedUnitSettings.unit.displayName,
                            color: .orange
                        )
                    }
                    .padding(.horizontal, 40)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }

                Spacer()

                // ステータスとコントロール
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
        .fullScreenCover(isPresented: $showingSettings) {
            SettingsView(locationManager: locationManager)
        }
        .animation(.easeInOut(duration: 0.3), value: premiumSettings.themeColor)
        .animation(.easeInOut(duration: 0.3), value: locationManager.isTracking)
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

// ② 速度統計カードコンポーネント
struct SpeedStatCard: View {
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(color.opacity(0.8))
                .tracking(2)

            Text(value)
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.3), value: value)

            Text(unit)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

#Preview {
    SpeedView(locationManager: LocationManager())
}
