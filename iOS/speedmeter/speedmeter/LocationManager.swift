//
//  LocationManager.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import Foundation
import CoreLocation
import Combine

enum SimulatedSpeed: String, CaseIterable, Identifiable {
    case none = "None"
    case walking = "Walking (5 km/h)"
    case running = "Running (12 km/h)"
    case cycling = "Cycling (25 km/h)"
    case driving = "Driving (60 km/h)"
    case highway = "Highway (100 km/h)"

    var id: String { rawValue }

    var speedKmh: Double? {
        switch self {
        case .none: return nil
        case .walking: return 5
        case .running: return 12
        case .cycling: return 25
        case .driving: return 60
        case .highway: return 100
        }
    }
}

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var lastRecordTime: Date?
    private let recordInterval: TimeInterval = 5.0 // Record every 5 seconds
    private var simulationTimer: Timer?

    @Published var speed: Double = 0.0 // m/s
    @Published var speedKmh: Double = 0.0 // km/h
    @Published var isTracking: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var simulatedSpeed: SimulatedSpeed = .none {
        didSet {
            updateSimulation()
        }
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        locationManager.startUpdatingLocation()
        isTracking = true
    }

    func stopTracking() {
        locationManager.stopUpdatingLocation()
        simulationTimer?.invalidate()
        simulationTimer = nil
        isTracking = false
        speed = 0.0
        speedKmh = 0.0
    }

    private func updateSimulation() {
        simulationTimer?.invalidate()
        simulationTimer = nil

        guard let simSpeed = simulatedSpeed.speedKmh else {
            return
        }

        simulationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let variation = Double.random(in: -2...2)
            self.speedKmh = max(0, simSpeed + variation)
            self.speed = self.speedKmh / 3.6
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // speed is in m/s, negative if invalid
        if location.speed >= 0 {
            speed = location.speed
            speedKmh = speed * 3.6 // convert m/s to km/h
        }

        // Record location at intervals
        let now = Date()
        if lastRecordTime == nil || now.timeIntervalSince(lastRecordTime!) >= recordInterval {
            lastRecordTime = now
            let record = LocationRecord(location: location)
            Task { @MainActor in
                LocationHistoryStore.shared.addRecord(record)
            }
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
