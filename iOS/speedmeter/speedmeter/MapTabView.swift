//
//  MapTabView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import MapKit

/// 地図表示用のレコードフィルタ
struct MapRecordFilter {
    /// 指定された領域内のレコードをフィルタし、最大数を制限
    static func filterRecords(_ records: [LocationRecord], in region: MKCoordinateRegion?, maxCount: Int) -> [LocationRecord] {
        let filtered: [LocationRecord]

        if let region = region {
            let latDelta = region.span.latitudeDelta / 2
            let lonDelta = region.span.longitudeDelta / 2
            let latRange = (region.center.latitude - latDelta)...(region.center.latitude + latDelta)
            let lonRange = (region.center.longitude - lonDelta)...(region.center.longitude + lonDelta)

            filtered = records.filter { record in
                latRange.contains(record.latitude) && lonRange.contains(record.longitude)
            }
        } else {
            filtered = records
        }

        // 最大数を超える場合は間引き
        if filtered.count <= maxCount {
            return filtered
        }
        let step = filtered.count / maxCount
        return stride(from: 0, to: filtered.count, by: max(1, step)).map { filtered[$0] }
    }
}

struct MapTabView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var historyStore = LocationHistoryStore.shared
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showHistory = true
    @State private var visibleRegion: MKCoordinateRegion?

    private let maxVisiblePins = 200

    /// 表示領域内のレコードをフィルタして最大数を制限
    private var visibleRecords: [LocationRecord] {
        guard showHistory else { return [] }
        return MapRecordFilter.filterRecords(historyStore.records, in: visibleRegion, maxCount: maxVisiblePins)
    }

    var body: some View {
        ZStack {
            Map(position: $position) {
                UserAnnotation()

                ForEach(visibleRecords) { record in
                    Annotation(
                        String(format: "%.0f km/h", record.speedKmh),
                        coordinate: CLLocationCoordinate2D(
                            latitude: record.latitude,
                            longitude: record.longitude
                        )
                    ) {
                        Circle()
                            .fill(speedColor(record.speedKmh))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                            )
                    }
                }
            }
            .onMapCameraChange { context in
                visibleRegion = context.region
            }
            .mapControls {
                MapUserLocationButton()
                MapCompass()
                MapScaleView()
            }

            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        showHistory.toggle()
                    } label: {
                        Image(systemName: showHistory ? "point.filled.topleft.down.curvedto.point.bottomright.up" : "point.topleft.down.curvedto.point.bottomright.up")
                            .font(.title2)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding()
                }
            }
        }
    }

    private func speedColor(_ speed: Double) -> Color {
        switch speed {
        case 0..<20:
            return .green
        case 20..<40:
            return .yellow
        case 40..<60:
            return .orange
        default:
            return .red
        }
    }
}

#Preview {
    MapTabView(locationManager: LocationManager())
}
