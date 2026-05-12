//
//  SetSpeedWarningIntent.swift
//  speedmeter
//

import AppIntents

struct SetSpeedWarningIntent: AppIntent {
    static var title: LocalizedStringResource = "Set Speed Warning"
    static var description = IntentDescription("Set the speed warning threshold in km/h.")

    @Parameter(title: "Speed (km/h)", description: "The speed limit in km/h that triggers the warning.", requestValueDialog: "What speed limit should trigger the warning? (in km/h)")
    var speedKmh: Double

    static var parameterSummary: some ParameterSummary {
        Summary("Set speed warning to \(\.$speedKmh) km/h")
    }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard speedKmh > 0 else {
            throw $speedKmh.needsValueError("Please enter a positive speed value.")
        }

        await MainActor.run {
            let unit = SpeedUnitSettings.shared.unit
            let threshold = unit.convert(speedKmh)
            SpeedWarningSettings.shared.threshold = threshold
            SpeedWarningSettings.shared.isEnabled = true
        }

        let unitName = await MainActor.run { SpeedUnitSettings.shared.unit.displayName }
        let converted = await MainActor.run { SpeedUnitSettings.shared.unit.convert(speedKmh) }
        return .result(dialog: "Speed warning set to \(Int(converted)) \(unitName).")
    }
}
