//
//  SettingsView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/13.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var historyStore = LocationHistoryStore.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingClearAlert = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    if historyStore.records.isEmpty {
                        Text("No location history")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(historyStore.records) { record in
                            LocationRecordRow(record: record, dateFormatter: dateFormatter)
                        }
                        .onDelete { offsets in
                            historyStore.deleteRecord(at: offsets)
                        }
                    }
                } header: {
                    HStack {
                        Text("Location History")
                        Spacer()
                        Text("\(historyStore.records.count) records")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if !historyStore.records.isEmpty {
                    Section {
                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Text("Clear All History")
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Clear History", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    historyStore.clearHistory()
                }
            } message: {
                Text("Are you sure you want to delete all location history? This action cannot be undone.")
            }
        }
    }
}

struct LocationRecordRow: View {
    let record: LocationRecord
    let dateFormatter: DateFormatter

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(String(format: "%.1f km/h", record.speedKmh))
                    .font(.headline)
                Spacer()
                Text(dateFormatter.string(from: record.timestamp))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.4f, %.4f", record.latitude, record.longitude))
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "arrow.up")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(String(format: "%.0fm", record.altitude))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    SettingsView()
}
