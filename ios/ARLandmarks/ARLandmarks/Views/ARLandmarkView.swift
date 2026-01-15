//
//  ARLandmarkView.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import SwiftUI
import ARKit

struct ARLandmarkView: View {
    let landmarks: [Landmark]
    @StateObject private var modeManager = ARModeManager()
    @State private var selectedLandmark: Landmark?
    @State private var showingDetail = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            ARViewContainer(
                landmarks: landmarks,
                selectedLandmark: $selectedLandmark,
                modeManager: modeManager
            )
            .ignoresSafeArea()
            
            VStack {
                topBar
                
                Spacer()
                
                if let landmark = selectedLandmark ?? modeManager.recognizedLandmark {
                    landmarkInfoCard(landmark)
                }
                
                modeSwitcher
            }
            .padding()
        }
        .onAppear {
            modeManager.startSession()
            modeManager.updateNearbyLandmarks(allLandmarks: landmarks)
        }
        .onDisappear {
            modeManager.stopSession()
        }
        .sheet(isPresented: $showingDetail) {
            if let landmark = selectedLandmark {
                LandmarkDetailSheet(
                    landmark: landmark,
                    weather: modeManager.weather
                )
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var displayedLandmarks: [Landmark] {
        switch modeManager.currentMode {
        case .visualRecognition:
            if let recognized = modeManager.recognizedLandmark {
                return [recognized]
            }
            return []
        case .geoBased:
            return modeManager.nearbyLandmarks
        }
    }
    
    // MARK: - View Components
    
    private var topBar: some View {
        HStack {
            HStack(spacing: 8) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.backward")
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
                        
            Spacer()
                        
            HStack(spacing: 4) {
                Image(systemName: "mappin.and.ellipse")
                Text("\(landmarks.count) Wahrzeichen")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
                        
            if let weather = modeManager.weather {
                HStack(spacing: 4) {
                Text(weather.iconEmoji)
                Text(weather.temperatureFormatted)
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(20)
            }
        }
    }
    
    private func landmarkInfoCard(_ landmark: Landmark) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(hex: landmark.category?.color ?? "#3B82F6").opacity(0.15))
                        .frame(width: 48, height: 48)

                    Text(landmark.category?.icon ?? "📍")
                        .font(.system(size: 24))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(landmark.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)

                    if let category = landmark.category {
                        Text(category.name)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: category.color))
                    }
                }

                Spacer()

                Button {
                    showingDetail = true
                } label: {
                    Image(systemName: "info.circle")
                }
            }
            
            if let distance = modeManager.locationService.distance(to: landmark) {
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                    Text(formatDistance(distance))
                }
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(8)
            }

            if let description = landmark.description {
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding()
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal)
        .padding(.bottom, 4)
    }
    
    private var modeSwitcher: some View {
            HStack(spacing: 12) {
                ForEach(ARModeManager.ARMode.allCases, id: \.self) { mode in
                    Button {
                        withAnimation {
                            if mode == .visualRecognition {
                                modeManager.switchToVisualMode()
                            } else {
                                modeManager.switchToGeoMode()
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                            if modeManager.currentMode == mode {
                                Text(mode.rawValue)
                                    .font(.caption)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(modeManager.currentMode == mode ? Color.blue : Color.clear)
                        .foregroundColor(modeManager.currentMode == mode ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding(4)
            .background(.ultraThinMaterial)
            .cornerRadius(24)
        }
    
    // MARK: - Helpers
    
    private func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            return "\(Int(meters)) m"
        } else {
            return String(format: "%.1f km", meters / 1000)
        }
    }
}

// MARK: - Landmark Detail Sheet

struct LandmarkDetailSheet: View {
    let landmark: Landmark
    let weather: Weather?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(hex: landmark.category?.color ?? "#3B82F6").opacity(0.15))
                            .frame(width: 64, height: 64)
                        
                        Text(landmark.category?.icon ?? "📍")
                            .font(.system(size: 32))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(landmark.name)
                            .font(.system(size: 22, weight: .bold))
                        
                        if let category = landmark.category {
                            Text(category.name)
                                .font(.system(size: 15))
                                .foregroundColor(Color(hex: category.color))
                        }
                    }
                }
                
                Divider()
                
                if let description = landmark.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Beschreibung")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.secondary)
                        
                        Text(description)
                            .font(.system(size: 15))
                    }
                }
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.secondary)
                    
                    if let year = landmark.yearBuilt {
                        detailRow(icon: "calendar", title: "Baujahr", value: "\(year)")
                    }
                    
                    if let architect = landmark.architect {
                        detailRow(icon: "person", title: "Architekt", value: architect)
                    }
                    
                    detailRow(
                        icon: "location",
                        title: "Koordinaten",
                        value: String(format: "%.4f°N, %.4f°E", landmark.latitude, landmark.longitude)
                    )
                    
                    if landmark.altitude > 0 {
                        detailRow(icon: "arrow.up", title: "Höhe", value: "\(Int(landmark.altitude)) m")
                    }
                }
            }
            .padding()
        }
        .presentationDragIndicator(.visible)
    }
    
    private func detailRow(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
    }
}

#Preview {
    ARLandmarkView(landmarks: [])
}
