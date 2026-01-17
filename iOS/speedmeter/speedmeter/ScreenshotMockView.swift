//
//  ScreenshotMockView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import MapKit

// MARK: - Screenshot Language
enum ScreenshotLanguage: String, CaseIterable {
    case english = "en"
    case japanese = "ja"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .japanese: return "日本語"
        }
    }

    // Localized strings
    var speed: String { self == .english ? "Speed" : "速度" }
    var map: String { self == .english ? "Map" : "マップ" }
    var kmh: String { self == .english ? "km/h" : "km/h" }
    var gpsActive: String { self == .english ? "GPS Active" : "GPS アクティブ" }
    var stop: String { self == .english ? "Stop" : "停止" }
    var settings: String { self == .english ? "Settings" : "設定" }
    var done: String { self == .english ? "Done" : "完了" }
    var proPlan: String { self == .english ? "Pro Plan" : "Proプラン" }
    var upgradeToPro: String { self == .english ? "Upgrade to Pro" : "Proにアップグレード" }
    var proDescription: String { self == .english ? "Ad-free, custom fonts & themes, unlimited history" : "広告なし、カスタムフォント＆テーマ、無制限の履歴" }
    var theme: String { self == .english ? "Theme" : "テーマ" }
    var white: String { self == .english ? "White" : "ホワイト" }
    var speedFont: String { self == .english ? "Speed Font" : "速度フォント" }
    var system: String { self == .english ? "System" : "システム" }
    var locationHistory: String { self == .english ? "Location History" : "位置履歴" }
    var records: String { self == .english ? "records" : "件" }

    // Paywall
    var speedmeterPro: String { self == .english ? "Speedmeter Pro" : "Speedmeter Pro" }
    var unlockAllFeatures: String { self == .english ? "Unlock all features" : "すべての機能をアンロック" }
    var adFree: String { self == .english ? "Ad-Free" : "広告なし" }
    var adFreeDescription: String { self == .english ? "Remove all banner ads" : "すべてのバナー広告を削除" }
    var customFonts: String { self == .english ? "Custom Fonts" : "カスタムフォント" }
    var customFontsDescription: String { self == .english ? "Choose from 8 additional fonts" : "8種類の追加フォントから選択" }
    var customThemes: String { self == .english ? "Custom Themes" : "カスタムテーマ" }
    var customThemesDescription: String { self == .english ? "Choose from 4 additional themes" : "4種類の追加テーマから選択" }
    var unlimitedHistory: String { self == .english ? "Unlimited History" : "無制限の履歴" }
    var unlimitedHistoryDescription: String { self == .english ? "Save location history without limits" : "位置履歴を無制限に保存" }
}

struct ScreenshotMockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedLanguage: ScreenshotLanguage?
    @State private var selectedTab = 0

    var body: some View {
        if let language = selectedLanguage {
            TabView(selection: $selectedTab) {
                MockSpeedView(language: language)
                    .tabItem {
                        Image(systemName: "speedometer")
                        Text(language.speed)
                    }
                    .tag(0)

                MockMapView(language: language)
                    .tabItem {
                        Image(systemName: "map")
                        Text(language.map)
                    }
                    .tag(1)
            }
        } else {
            // Language Selection
            VStack(spacing: 32) {
                Text("Select Language")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("言語を選択")
                    .font(.title2)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    ForEach(ScreenshotLanguage.allCases, id: \.self) { language in
                        Button {
                            selectedLanguage = language
                        } label: {
                            Text(language.displayName)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .frame(height: 60)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Mock Speed View
struct MockSpeedView: View {
    let language: ScreenshotLanguage
    @State private var showingSettings = false

    var body: some View {
        ZStack {
            Color.black
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

                VStack(spacing: 8) {
                    Text("42")
                        .font(.system(size: 120, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)

                    Text(language.kmh)
                        .font(.title)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                        Text(language.gpsActive)
                            .foregroundColor(.green)
                    }

                    Text(language.stop)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(width: 200, height: 50)
                        .background(Color.red)
                        .cornerRadius(25)
                }
                .padding(.bottom, 20)
            }
        }
        .fullScreenCover(isPresented: $showingSettings) {
            MockSettingsView(language: language)
        }
    }
}

// MARK: - Mock Map View
struct MockMapView: View {
    let language: ScreenshotLanguage
    // 皇居周辺
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 35.6838, longitude: 139.7540),
        span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
    ))

    // 内堀通り沿いのルート（時計回り）
    private let mockRecords: [(lat: Double, lon: Double, speed: Double)] = [
        // 1. 大手町駅付近（スタート）
        (35.6867, 139.7629, 15),
        // 2. 竹橋交差点
        (35.6912, 139.7576, 42),
        // 3. 九段下交差点付近
        (35.6940, 139.7510, 48),
        // 4. 千鳥ヶ淵交差点
        (35.6905, 139.7455, 52),
        // 5. 半蔵門交差点
        (35.6832, 139.7410, 18),
        // 6. 三宅坂交差点
        (35.6782, 139.7450, 45),
        // 7. 桜田門交差点
        (35.6755, 139.7505, 25),
        // 8. 日比谷交差点
        (35.6740, 139.7580, 38),
        // 9. 祝田橋交差点
        (35.6765, 139.7610, 42),
        // 10. 馬場先門
        (35.6810, 139.7640, 35),
    ]

    var body: some View {
        ZStack {
            Map(position: $position) {
                // 現在地風のマーカー
                Annotation("", coordinate: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671)) {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 3)
                        )
                        .shadow(radius: 3)
                }

                // 履歴ピン
                ForEach(0..<mockRecords.count, id: \.self) { index in
                    let record = mockRecords[index]
                    Annotation(
                        String(format: "%.0f km/h", record.speed),
                        coordinate: CLLocationCoordinate2D(latitude: record.lat, longitude: record.lon)
                    ) {
                        Circle()
                            .fill(speedColor(record.speed))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
            }
            .mapControls { }

            // 履歴ボタン（右下）
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "point.filled.topleft.down.curvedto.point.bottomright.up")
                        .font(.title2)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding()
                }
            }
        }
    }

    private func speedColor(_ speed: Double) -> Color {
        switch speed {
        case 0..<20:
            return .green
        case 20..<40:
            return .yellow
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}

// MARK: - Mock Paywall View (価格表示なし)
struct MockPaywallView: View {
    let language: ScreenshotLanguage
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.purple.opacity(0.3)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.yellow)

                            Text(language.speedmeterPro)
                                .font(.largeTitle)
                                .fontWeight(.bold)

                            Text(language.unlockAllFeatures)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 32)

                        // Features
                        VStack(spacing: 12) {
                            MockFeatureRow(
                                icon: "xmark.circle.fill",
                                iconColor: .red,
                                title: language.adFree,
                                description: language.adFreeDescription
                            )

                            MockFeatureRow(
                                icon: "textformat",
                                iconColor: .orange,
                                title: language.customFonts,
                                description: language.customFontsDescription
                            )

                            MockFeatureRow(
                                icon: "paintpalette.fill",
                                iconColor: .purple,
                                title: language.customThemes,
                                description: language.customThemesDescription
                            )

                            MockFeatureRow(
                                icon: "infinity",
                                iconColor: .blue,
                                title: language.unlimitedHistory,
                                description: language.unlimitedHistoryDescription
                            )
                        }
                        .padding(.horizontal)

                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
}

struct MockFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.9))
        .cornerRadius(12)
    }
}

// MARK: - Mock Settings View
struct MockSettingsView: View {
    let language: ScreenshotLanguage
    @Environment(\.dismiss) private var dismiss
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        showingPaywall = true
                    } label: {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(language.upgradeToPro)
                                    .foregroundColor(.primary)
                                Text(language.proDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text(language.proPlan)
                }

                Section {
                    HStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        Text(language.white)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text(language.theme)
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(language.system)
                            Text("123")
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text(language.speedFont)
                }

                Section {
                    NavigationLink {
                        MockLocationHistoryView(language: language)
                    } label: {
                        HStack {
                            Text(language.locationHistory)
                            Spacer()
                            Text("10 \(language.records)")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(language.settings)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(language.done) {
                        dismiss()
                    }
                }
            }
            .fullScreenCover(isPresented: $showingPaywall) {
                MockPaywallView(language: language)
            }
        }
    }
}

// MARK: - Mock Location History View
struct MockLocationHistoryView: View {
    let language: ScreenshotLanguage
    private let mockRecords: [(speed: Double, lat: Double, lon: Double, altitude: Double, time: String)] = [
        (52.3, 35.6905, 139.7455, 12, "14:32:15"),
        (48.1, 35.6940, 139.7510, 15, "14:31:42"),
        (45.2, 35.6782, 139.7450, 18, "14:30:58"),
        (42.0, 35.6867, 139.7629, 10, "14:30:21"),
        (38.5, 35.6740, 139.7580, 8, "14:29:45"),
        (35.0, 35.6810, 139.7640, 11, "14:29:02"),
        (25.3, 35.6755, 139.7505, 14, "14:28:18"),
        (18.7, 35.6832, 139.7410, 16, "14:27:35"),
        (15.2, 35.6912, 139.7576, 13, "14:26:52"),
        (42.8, 35.6765, 139.7610, 9, "14:26:08"),
    ]

    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<mockRecords.count, id: \.self) { index in
                    let record = mockRecords[index]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(format: "%.1f km/h", record.speed))
                                .font(.headline)
                            Spacer()
                            Text("2025/12/30 \(record.time)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Image(systemName: "location.fill")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.4f, %.4f", record.lat, record.lon))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            Image(systemName: "arrow.up")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0fm", record.altitude))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            .navigationTitle(language.locationHistory)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ScreenshotMockView()
}
