//
//  StopSpeedTrackingIntent.swift
//  speedmeter
//

import AppIntents

struct StopSpeedTrackingIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Speed Tracking"
    static var description = IntentDescription("Stop measuring your GPS speed with SpeedMeter.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        await MainActor.run {
            LocationManager.shared.stopTracking()
        }
        return .result(dialog: "Speed tracking has stopped.")
    }
}
