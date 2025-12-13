//
//  LocationManager.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    private var lastRecordTime: Date?
    private let recordInterval: TimeInterval = 5.0 // Record every 5 seconds

    @Published var speed: Double = 0.0 // m/s
    @Published var speedKmh: Double = 0.0 // km/h
    @Published var isTracking: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined

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
        isTracking = false
        speed = 0.0
        speedKmh = 0.0
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
