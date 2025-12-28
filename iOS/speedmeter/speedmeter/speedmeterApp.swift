//
//  speedmeterApp.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import SwiftUI
import UIKit

@main
struct speedmeterApp: App {
    init() {
        print("=== App Started ===")
        print("Total font families: \(UIFont.familyNames.count)")

        // DSEGフォントを探す
        let dsegFonts = UIFont.familyNames.filter { $0.contains("DSEG") }
        if dsegFonts.isEmpty {
            print("DSEG fonts NOT found")
        } else {
            for family in dsegFonts {
                print("Font Family: \(family)")
                for name in UIFont.fontNames(forFamilyName: family) {
                    print("  - \(name)")
                }
            }
        }
        print("===================")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
