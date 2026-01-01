//
//  ScreenshotMockView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import MapKit

struct ScreenshotMockView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MockSpeedView()
                .tabItem {
                    Image(systemName: "speedometer")
                    Text("Speed")
                }
                .tag(0)

            MockMapView()
                .tabItem {
                    Image(systemName: "map")
                    Text("Map")
                }
                .tag(1)
        }
    }
}

// MARK: - Mock Speed View
struct MockSpeedView: View {
    @ObservedObject private var fontSettings = FontSettings.shared
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
                        .font(fontSettings.selectedFont.font(size: 120))
                        .foregroundColor(.white)

                    Text("km/h")
                        .font(.title)
                        .foregroundColor(.gray)
                }

                Spacer()

                VStack(spacing: 16) {
                    HStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 10, height: 10)
                        Text("GPS Active")
                            .foregroundColor(.green)
                    }

                    Text("Stop")
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
        .sheet(isPresented: $showingSettings) {
            MockSettingsView()
        }
    }
}

// MARK: - Mock Map View
struct MockMapView: View {
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

// MARK: - Mock Settings View
struct MockSettingsView: View {
    @ObservedObject private var fontSettings = FontSettings.shared
    @ObservedObject private var premiumSettings = PremiumSettings.shared

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Circle()
                            .fill(premiumSettings.themeColor.color)
                            .frame(width: 24, height: 24)
                        Text(premiumSettings.themeColor.displayName)
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("テーマ")
                }

                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fontSettings.selectedFont.displayName)
                            Text("123")
                                .font(fontSettings.selectedFont.font(size: 24))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark")
                            .foregroundColor(.blue)
                    }
                } header: {
                    Text("Speed Font")
                }

                Section {
                    NavigationLink {
                        MockLocationHistoryView()
                    } label: {
                        HStack {
                            Text("Location History")
                            Spacer()
                            Text("10 records")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Mock Location History View
struct MockLocationHistoryView: View {
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
            .navigationTitle("Location History")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ScreenshotMockView()
}
