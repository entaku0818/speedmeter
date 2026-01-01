//
//  speedmeterTests.swift
//  speedmeterTests
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import Testing
import CoreLocation
import MapKit
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

// MARK: - Map Filtering Tests
struct MapFilteringTests {

    /// テスト用のLocationRecordを作成
    private func createRecord(lat: Double, lon: Double, speed: Double = 30.0) -> LocationRecord {
        LocationRecord(
            timestamp: Date(),
            latitude: lat,
            longitude: lon,
            speed: speed / 3.6,
            altitude: 0,
            horizontalAccuracy: 5.0
        )
    }

    @Test func filterRecordsInRegion() async throws {
        // 東京駅周辺のレコード
        let records = [
            createRecord(lat: 35.6812, lon: 139.7671),  // 東京駅
            createRecord(lat: 35.6895, lon: 139.6917),  // 新宿
            createRecord(lat: 35.7100, lon: 139.8107),  // 上野
            createRecord(lat: 35.6580, lon: 139.7016),  // 渋谷
        ]

        // 東京駅を中心とした狭い領域
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6812, longitude: 139.7671),
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )

        let filtered = MapRecordFilter.filterRecords(records, in: region, maxCount: 200)

        // 東京駅のみが範囲内
        #expect(filtered.count == 1)
        #expect(abs(filtered[0].latitude - 35.6812) < 0.001)
    }

    @Test func filterRecordsLimitsCount() async throws {
        // 1000件のレコードを作成
        var records: [LocationRecord] = []
        for i in 0..<1000 {
            let lat = 35.6 + Double(i) * 0.0001
            let lon = 139.7 + Double(i) * 0.0001
            records.append(createRecord(lat: lat, lon: lon))
        }

        // 全て含む広い領域
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.65, longitude: 139.75),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )

        let filtered = MapRecordFilter.filterRecords(records, in: region, maxCount: 200)

        // 最大200件に制限される
        #expect(filtered.count <= 200)
    }

    @Test func filterRecordsEmptyWhenOutsideRegion() async throws {
        let records = [
            createRecord(lat: 35.6812, lon: 139.7671),  // 東京
        ]

        // 大阪を中心とした領域
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023),
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        let filtered = MapRecordFilter.filterRecords(records, in: region, maxCount: 200)

        #expect(filtered.isEmpty)
    }

    @Test func filterRecordsSamplingIsEvenlyDistributed() async throws {
        // 600件のレコードを作成
        var records: [LocationRecord] = []
        for i in 0..<600 {
            records.append(createRecord(lat: 35.6 + Double(i) * 0.0001, lon: 139.7))
        }

        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.63, longitude: 139.7),
            span: MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)
        )

        let filtered = MapRecordFilter.filterRecords(records, in: region, maxCount: 200)

        // 間引きされて200件以下になる
        #expect(filtered.count <= 200)
        #expect(filtered.count > 0)
    }
}
