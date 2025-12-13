//
//  LocationRecord.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import Foundation
import CoreLocation

struct LocationRecord: Identifiable, Codable, Equatable {
    let id: UUID
    let timestamp: Date
    let latitude: Double
    let longitude: Double
    let speed: Double // m/s
    let speedKmh: Double // km/h
    let altitude: Double
    let horizontalAccuracy: Double

    init(id: UUID = UUID(), location: CLLocation) {
        self.id = id
        self.timestamp = location.timestamp
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.speed = max(0, location.speed)
        self.speedKmh = max(0, location.speed * 3.6)
        self.altitude = location.altitude
        self.horizontalAccuracy = location.horizontalAccuracy
    }

    init(id: UUID = UUID(), timestamp: Date, latitude: Double, longitude: Double, speed: Double, altitude: Double, horizontalAccuracy: Double) {
        self.id = id
        self.timestamp = timestamp
        self.latitude = latitude
        self.longitude = longitude
        self.speed = speed
        self.speedKmh = speed * 3.6
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
    }
}
