//
//  MapTabView.swift
//  speedmeter
//
//  Created by 遠藤拓弥 on 2025/12/29.
//

import SwiftUI
import MapKit

struct MapTabView: View {
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var historyStore = LocationHistoryStore.shared
    @State private var position: MapCameraPosition = .userLocation(fallback: .automatic)
    @State private var showHistory = true

    var body: some View {
        ZStack {
            Map(position: $position) {
                UserAnnotation()

                if showHistory {
                    ForEach(historyStore.records) { record in
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
