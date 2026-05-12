//
//  StartSpeedTrackingIntent.swift
//  speedmeter
//

import AppIntents
import CoreLocation

struct StartSpeedTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Speed Tracking"
    static var description = IntentDescription("Start measuring your GPS speed with SpeedMeter.")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            let lm = LocationManager.shared
            if !lm.isTracking {
                if lm.authorizationStatus == .authorizedAlways || lm.authorizationStatus == .authorizedWhenInUse {
                    lm.startTracking()
                } else {
                    lm.requestPermission()
                }
            }
        }
        return .result(dialog: "Speed tracking has started.")
    }
}
