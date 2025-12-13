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

    private let maxRecords = 1000
    private let saveKey = "locationHistory"

    static let shared = LocationHistoryStore()

    private init() {
        load()
    }

    func addRecord(_ record: LocationRecord) {
        records.insert(record, at: 0)

        if records.count > maxRecords {
            records = Array(records.prefix(maxRecords))
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
}
