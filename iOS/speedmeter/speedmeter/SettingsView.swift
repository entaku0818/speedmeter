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

    var isPremiumOnly: Bool {
        switch self {
        case .digital7Modern, .digital7Classic:
            return false
        default:
            return true
        }
    }

    static var freeFonts: [SpeedFont] {
        allCases.filter { !$0.isPremiumOnly }
    }

    static var allFontsForPremium: [SpeedFont] {
        allCases
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
}

struct SettingsView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var historyStore = LocationHistoryStore.shared
    @ObservedObject private var fontSettings = FontSettings.shared
    @ObservedObject private var purchaseManager = PurchaseManager.shared
    @ObservedObject private var premiumSettings = PremiumSettings.shared
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
                                    Text("Proにアップグレード")
                                        .foregroundColor(.primary)
                                    Text("広告非表示、フォント・テーマ変更など")
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

                // Premium Settings (for Pro users)
                if purchaseManager.isPremium {
                    Section {
                        ForEach(ThemeColor.allCases) { theme in
                            HStack {
                                Circle()
                                    .fill(theme.color)
                                    .frame(width: 24, height: 24)
                                Text(theme.displayName)
                                Spacer()
                                if premiumSettings.themeColor == theme {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                premiumSettings.themeColor = theme
                            }
                        }
                    } header: {
                        Text("テーマ")
                    }
                }

                Section {
                    let availableFonts = purchaseManager.isPremium ? SpeedFont.allFontsForPremium : SpeedFont.freeFonts
                    ForEach(availableFonts) { font in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text(font.displayName)
                                    if font.isPremiumOnly {
                                        Image(systemName: "crown.fill")
                                            .font(.caption2)
                                            .foregroundColor(.yellow)
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
                            fontSettings.selectedFont = font
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
        .alert("Clear History", isPresented: $showingClearAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Clear", role: .destructive) {
                historyStore.clearHistory()
            }
        } message: {
            Text("Are you sure you want to delete all location history? This action cannot be undone.")
        }
    }
}

struct LocationRecordRow: View {
    let record: LocationRecord
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(format: "%.1f km/h", record.speedKmh))
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

#Preview {
    SettingsView(locationManager: LocationManager())
}
