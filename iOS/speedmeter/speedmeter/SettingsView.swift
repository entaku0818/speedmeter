//
//  SettingsView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import SwiftUI
import Combine

enum SpeedFont: String, CaseIterable, Identifiable {
    case digital7Modern = "DSEG7Modern-Bold"
    case digital7Classic = "DSEG7Classic-Bold"
    case system = "system"
    case systemRounded = "systemRounded"
    case menlo = "Menlo-Bold"
    case courier = "Courier-Bold"
    case helveticaNeue = "HelveticaNeue-Bold"
    case avenir = "AvenirNext-Bold"
    case futura = "Futura-Bold"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: return "System"
        case .systemRounded: return "System Rounded"
        case .digital7Modern: return "Digital Modern"
        case .digital7Classic: return "Digital Classic"
        case .menlo: return "Menlo"
        case .courier: return "Courier"
        case .helveticaNeue: return "Helvetica Neue"
        case .avenir: return "Avenir Next"
        case .futura: return "Futura"
        }
    }

    var isFree: Bool {
        self == .digital7Modern
    }

    func font(size: CGFloat) -> Font {
        switch self {
        case .system:
            return .system(size: size, weight: .bold, design: .monospaced)
        case .systemRounded:
            return .system(size: size, weight: .bold, design: .rounded)
        case .digital7Modern, .digital7Classic, .menlo, .courier, .helveticaNeue, .avenir, .futura:
            return .custom(rawValue, size: size)
        }
    }
}

class FontSettings: ObservableObject {
    static let shared = FontSettings()

    @Published var selectedFont: SpeedFont {
        didSet {
            UserDefaults.standard.set(selectedFont.rawValue, forKey: "selectedSpeedFont")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedSpeedFont") ?? SpeedFont.digital7Modern.rawValue
        self.selectedFont = SpeedFont(rawValue: saved) ?? .digital7Modern
    }

    func resetToFree() {
        selectedFont = .digital7Modern
    }
}

// ① mph/km切り替え設定
enum SpeedUnit: String, CaseIterable, Identifiable {
    case kmh = "km/h"
    case mph = "mph"

    var id: String { rawValue }
    var displayName: String { rawValue }

    func convert(_ kmh: Double) -> Double {
        switch self {
        case .kmh: return kmh
        case .mph: return kmh * 0.621371
        }
    }
}

class SpeedUnitSettings: ObservableObject {
    static let shared = SpeedUnitSettings()

    @Published var unit: SpeedUnit {
        didSet {
            UserDefaults.standard.set(unit.rawValue, forKey: "selectedSpeedUnit")
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: "selectedSpeedUnit") ?? SpeedUnit.kmh.rawValue
        self.unit = SpeedUnit(rawValue: saved) ?? .kmh
    }
}

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var historyStore = LocationHistoryStore.shared
    @ObservedObject private var fontSettings = FontSettings.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var premiumSettings = PremiumSettings.shared
    @ObservedObject private var speedUnitSettings = SpeedUnitSettings.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingScreenshotMode = false
    @State private var showingPaywall = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                List {
                    // Pro Plan Section
                    if !purchaseManager.isPremium {
                        Section {
                            Button {
                                showingPaywall = true
                            } label: {
                                HStack {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Upgrade to Pro")
                                            .foregroundColor(.primary)
                                        Text("Ad-free, custom fonts & themes, unlimited history")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.secondary)
                                }
                            }
                        } header: {
                            Text("Pro Plan")
                        }
                    }

                    // ① Speed Unit Section
                    Section {
                        HStack(spacing: 0) {
                            ForEach(SpeedUnit.allCases) { unit in
                                Button {
                                    speedUnitSettings.unit = unit
                                } label: {
                                    HStack {
                                        Spacer()
                                        if speedUnitSettings.unit == unit {
                                            Image(systemName: "checkmark")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        }
                                        Text(unit.displayName)
                                            .font(.system(.body, design: .monospaced))
                                            .fontWeight(.semibold)
                                            .foregroundColor(speedUnitSettings.unit == unit ? .white : .primary)
                                        Spacer()
                                    }
                                    .padding(.vertical, 10)
                                    .background(speedUnitSettings.unit == unit ? Color.blue : Color.clear)
                                }
                                .buttonStyle(PlainButtonStyle())
                                if unit != SpeedUnit.allCases.last {
                                    Divider()
                                }
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    } header: {
                        Text("Speed Unit")
                    } footer: {
                        Text("Changes the unit displayed on the speedometer.")
                    }

                    Section {
                        ForEach(ThemeColor.allCases) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 24, height: 24)
                                Text(theme.displayName)
                                if !theme.isFree && !purchaseManager.isPremium {
                                    Image(systemName: "lock.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if premiumSettings.themeColor == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if theme.isFree || purchaseManager.isPremium {
                                    premiumSettings.themeColor = theme
                                } else {
                                    showingPaywall = true
                                }
                            }
                        }
                    } header: {
                        Text("Theme")
                    }

                    Section {
                        ForEach(SpeedFont.allCases) { font in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(font.displayName)
                                        if !font.isFree && !purchaseManager.isPremium {
                                            Image(systemName: "lock.fill")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    Text("123")
                                        .font(font.font(size: 24))
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if fontSettings.selectedFont == font {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if font.isFree || purchaseManager.isPremium {
                                    fontSettings.selectedFont = font
                                } else {
                                    showingPaywall = true
                                }
                            }
                        }
                    } header: {
                        Text("Speed Font")
                    }

                    Section {
                        NavigationLink {
                            LocationHistoryView()
                        } label: {
                            HStack {
                                Text("Location History")
                                Spacer()
                                Text("\(historyStore.records.count) records")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // ② 速度統計セクション
                    if !historyStore.records.isEmpty {
                        Section {
                            HStack {
                                Label("Average Speed", systemImage: "speedometer")
                                Spacer()
                                Text(speedUnitSettings.unit == .mph
                                    ? String(format: "%.1f mph", historyStore.averageSpeedKmh / 1.60934)
                                    : String(format: "%.1f km/h", historyStore.averageSpeedKmh))
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }
                            HStack {
                                Label("Max Speed", systemImage: "gauge.with.dots.needle.100percent")
                                Spacer()
                                Text(speedUnitSettings.unit == .mph
                                    ? String(format: "%.1f mph", historyStore.maxSpeedKmh / 1.60934)
                                    : String(format: "%.1f km/h", historyStore.maxSpeedKmh))
                                    .foregroundColor(.secondary)
                                    .font(.system(.body, design: .monospaced))
                            }
                            HStack {
                                Label("Total Records", systemImage: "chart.bar.fill")
                                Spacer()
                                Text("\(historyStore.records.count)")
                                    .foregroundColor(.secondary)
                            }
                        } header: {
                            Text("Statistics")
                        }
                    }

                    #if DEBUG
                    Section {
                        ForEach(SimulatedSpeed.allCases) { speed in
                            HStack {
                                Text(speed.rawValue)
                                Spacer()
                                if locationManager.simulatedSpeed == speed {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                locationManager.simulatedSpeed = speed
                            }
                        }
                    } header: {
                        Text("Debug: Simulate Speed")
                    }

                    Section {
                        Button {
                            showingScreenshotMode = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.viewfinder")
                                Text("Screenshot Mode")
                            }
                        }
                    } header: {
                        Text("Debug: Screenshots")
                    } footer: {
                        Text("Open mock screens for App Store screenshots")
                    }
                    #endif
                }

                if !purchaseManager.isPremium {
                    BannerAdView()
                        .frame(height: 50)
                        .background(Color.black)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            #if DEBUG
            .fullScreenCover(isPresented: $showingScreenshotMode) {
                ScreenshotMockView()
            }
            #endif
        }
        .preferredColorScheme(.dark)
    }
}

struct LocationHistoryView: View {
    @ObservedObject private var historyStore = LocationHistoryStore.shared
    @State private var showingClearAlert = false
    @State private var showExportPicker = false
    @State private var exportURL: URL?
    @State private var showShareSheet = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        List {
            if historyStore.records.isEmpty {
                Text("No location history")
                    .foregroundColor(.secondary)
            } else {
                ForEach(historyStore.records) { record in
                    LocationRecordRow(record: record, dateFormatter: dateFormatter)
                }
                .onDelete { offsets in
                    historyStore.deleteRecord(at: offsets)
                }
            }

            if !historyStore.records.isEmpty {
                Section {
                    Button(role: .destructive) {
                        showingClearAlert = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Clear All History")
                            Spacer()
                        }
                    }
                }
            }
        }
        .navigationTitle("Location History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            // ④ エクスポートボタン
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        prepareExport(asCSV: true)
                    } label: {
                        Label("Export as CSV", systemImage: "tablecells")
                    }
                    Button {
                        prepareExport(asCSV: false)
                    } label: {
                        Label("Export as GPX", systemImage: "map")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(historyStore.records.isEmpty)
            }
        }
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                historyStore.clearHistory()
            }
        } message: {
            Text("Are you sure you want to delete all location history? This action cannot be undone.")
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportURL {
                ActivitySheet(items: [url])
            }
        }
    }

    private func prepareExport(asCSV: Bool) {
        let content = asCSV ? historyStore.exportCSV() : historyStore.exportGPX()
        let filename = asCSV ? "speedmeter_history.csv" : "speedmeter_history.gpx"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            exportURL = url
            showShareSheet = true
        } catch {
            print("Export failed: \(error)")
        }
    }
}

struct LocationRecordRow: View {
    let record: LocationRecord
    let dateFormatter: DateFormatter
    @ObservedObject private var speedUnitSettings = SpeedUnitSettings.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                let speedText = speedUnitSettings.unit == .mph
                    ? String(format: "%.1f mph", record.speedKmh / 1.60934)
                    : String(format: "%.1f km/h", record.speedKmh)
                Text(speedText)
                    .font(.headline)
                Spacer()
                Text(dateFormatter.string(from: record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.4f, %.4f", record.latitude, record.longitude))
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

// ④ ShareSheet ラッパー（エクスポート用）
import UIKit
struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView(locationManager: LocationManager())
}
