//
//  SpeedMeterShortcuts.swift
//  speedmeter
//

import AppIntents

struct SpeedMeterShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSpeedTrackingIntent(),
            phrases: [
                "Start speed tracking in \(.applicationName)",
                "Begin measuring speed with \(.applicationName)",
                "\(.applicationName)で速度計測を開始",
                "\(.applicationName)の計測を開始して"
            ],
            shortTitle: "Start Tracking",
            systemImageName: "play.fill"
        )
        AppShortcut(
            intent: StopSpeedTrackingIntent(),
            phrases: [
                "Stop speed tracking in \(.applicationName)",
                "Stop measuring speed with \(.applicationName)",
                "\(.applicationName)で速度計測を停止",
                "\(.applicationName)の計測を停止して"
            ],
            shortTitle: "Stop Tracking",
            systemImageName: "stop.fill"
        )
        AppShortcut(
            intent: SetSpeedWarningIntent(),
            phrases: [
                "Set speed warning in \(.applicationName)",
                "\(.applicationName)で速度制限を設定",
                "\(.applicationName)の速度警告を設定して"
            ],
            shortTitle: "Set Speed Warning",
            systemImageName: "exclamationmark.triangle.fill"
        )
    }
}
