//
//  PremiumSettings.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import Combine

enum HistoryLimit: String, CaseIterable, Identifiable {
    case limit100 = "100"
    case limit500 = "500"
    case limit1000 = "1000"
    case limit5000 = "5000"
    case unlimited = "無制限"

    var id: String { rawValue }

    var value: Int? {
        switch self {
        case .limit100: return 100
        case .limit500: return 500
        case .limit1000: return 1000
        case .limit5000: return 5000
        case .unlimited: return nil
        }
    }

    var displayName: String {
        switch self {
        case .limit100: return "100件"
        case .limit500: return "500件"
        case .limit1000: return "1,000件"
        case .limit5000: return "5,000件"
        case .unlimited: return "無制限"
        }
    }
}

enum ThemeColor: String, CaseIterable, Identifiable {
    case black = "black"
    case darkBlue = "darkBlue"
    case darkGreen = "darkGreen"
    case darkRed = "darkRed"
    case darkPurple = "darkPurple"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .black: return "ブラック"
        case .darkBlue: return "ダークブルー"
        case .darkGreen: return "ダークグリーン"
        case .darkRed: return "ダークレッド"
        case .darkPurple: return "ダークパープル"
        }
    }

    var color: Color {
        switch self {
        case .black: return .black
        case .darkBlue: return Color(red: 0.05, green: 0.1, blue: 0.2)
        case .darkGreen: return Color(red: 0.05, green: 0.15, blue: 0.1)
        case .darkRed: return Color(red: 0.15, green: 0.05, blue: 0.05)
        case .darkPurple: return Color(red: 0.1, green: 0.05, blue: 0.15)
        }
    }
}

class PremiumSettings: ObservableObject {
    static let shared = PremiumSettings()

    @Published var historyLimit: HistoryLimit {
        didSet {
            UserDefaults.standard.set(historyLimit.rawValue, forKey: "premiumHistoryLimit")
        }
    }

    @Published var themeColor: ThemeColor {
        didSet {
            UserDefaults.standard.set(themeColor.rawValue, forKey: "premiumThemeColor")
        }
    }

    private init() {
        let savedLimit = UserDefaults.standard.string(forKey: "premiumHistoryLimit") ?? HistoryLimit.limit1000.rawValue
        self.historyLimit = HistoryLimit(rawValue: savedLimit) ?? .limit1000

        let savedTheme = UserDefaults.standard.string(forKey: "premiumThemeColor") ?? ThemeColor.black.rawValue
        self.themeColor = ThemeColor(rawValue: savedTheme) ?? .black
    }

    var maxRecords: Int? {
        return historyLimit.value
    }
}
