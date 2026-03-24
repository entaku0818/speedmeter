//
//  LocationHistoryStore.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class LocationHistoryStore: ObservableObject {
    @Published private(set) var records: [LocationRecord] = []

    private let freeMaxRecords = 1000
    private let saveKey = "locationHistory"

    static let shared = LocationHistoryStore()

    private init() {
        load()
    }

    func addRecord(_ record: LocationRecord) {
        records.insert(record, at: 0)

        // Pro版は無制限、無料版は1000件まで
        if !PurchaseManager.shared.isPremium && records.count > freeMaxRecords {
            records = Array(records.prefix(freeMaxRecords))
        }

        save()
    }

    func clearHistory() {
        records.removeAll()
        save()
    }

    func deleteRecord(at offsets: IndexSet) {
        records.remove(atOffsets: offsets)
        save()
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Failed to save location history: \(error)")
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: saveKey) else { return }

        do {
            records = try JSONDecoder().decode([LocationRecord].self, from: data)
        } catch {
            print("Failed to load location history: \(error)")
        }
    }

    // MARK: - Statistics
    var averageSpeedKmh: Double {
        guard !records.isEmpty else { return 0 }
        return records.map { $0.speedKmh }.reduce(0, +) / Double(records.count)
    }

    var maxSpeedKmh: Double {
        records.map { $0.speedKmh }.max() ?? 0
    }

    // MARK: - Export
    func exportCSV() -> String {
        let formatter = ISO8601DateFormatter()
        var csv = "timestamp,latitude,longitude,altitude_m,speed_kmh\n"
        for record in records.reversed() {
            csv += "\(formatter.string(from: record.timestamp)),\(record.latitude),\(record.longitude),\(String(format: "%.1f", record.altitude)),\(String(format: "%.2f", record.speedKmh))\n"
        }
        return csv
    }

    func exportGPX() -> String {
        let formatter = ISO8601DateFormatter()
        var lines = [
            "<?xml version=\"1.0\" encoding=\"UTF-8\"?>",
            "<gpx version=\"1.1\" creator=\"Speedmeter\">",
            "  <trk><name>Speedmeter Track</name><trkseg>"
        ]
        for record in records.reversed() {
            lines += [
                "    <trkpt lat=\"\(record.latitude)\" lon=\"\(record.longitude)\">",
                "      <ele>\(String(format: "%.1f", record.altitude))</ele>",
                "      <time>\(formatter.string(from: record.timestamp))</time>",
                "      <extensions><speed>\(String(format: "%.3f", record.speed))</speed></extensions>",
                "    </trkpt>"
            ]
        }
        lines += ["  </trkseg></trk>", "</gpx>"]
        return lines.joined(separator: "\n")
    }
}
