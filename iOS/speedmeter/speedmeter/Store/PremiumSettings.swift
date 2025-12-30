//
//  PremiumSettings.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import Combine

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

    @Published var themeColor: ThemeColor {
        didSet {
            UserDefaults.standard.set(themeColor.rawValue, forKey: "premiumThemeColor")
        }
    }

    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: "premiumThemeColor") ?? ThemeColor.black.rawValue
        self.themeColor = ThemeColor(rawValue: savedTheme) ?? .black
    }
}
