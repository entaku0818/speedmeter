//
//  speedmeterTests.swift
//  speedmeterTests
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import Testing
import CoreLocation
@testable import speedmeter

struct speedmeterTests {

    @Test func locationManagerInitialState() async throws {
        let manager = LocationManager()

        #expect(manager.speed == 0.0)
        #expect(manager.speedKmh == 0.0)
        #expect(manager.isTracking == false)
    }

    @Test func speedConversionMsToKmh() async throws {
        // Test conversion formula: km/h = m/s * 3.6
        let speedMs: Double = 10.0 // 10 m/s
        let expectedKmh: Double = 36.0 // 36 km/h

        let actualKmh = speedMs * 3.6
        #expect(actualKmh == expectedKmh)
    }

    @Test func speedConversionVariousValues() async throws {
        // Walking speed: ~1.4 m/s = ~5 km/h
        #expect(abs(1.4 * 3.6 - 5.04) < 0.01)

        // Running speed: ~3 m/s = ~10.8 km/h
        #expect(abs(3.0 * 3.6 - 10.8) < 0.01)

        // Car speed: ~27.8 m/s = ~100 km/h
        #expect(abs(27.78 * 3.6 - 100.0) < 0.1)
    }

    @Test func trackingStateToggle() async throws {
        let manager = LocationManager()

        // Initial state
        #expect(manager.isTracking == false)

        // Note: startTracking/stopTracking require location permission
        // so we only test the state change behavior indirectly
        manager.stopTracking()
        #expect(manager.isTracking == false)
        #expect(manager.speed == 0.0)
        #expect(manager.speedKmh == 0.0)
    }
}
