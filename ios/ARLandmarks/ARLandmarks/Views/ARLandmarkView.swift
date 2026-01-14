//
//  ARLandmarkView.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import SwiftUI

struct ARLandmarkView: View {
    let landmarks: [Landmark]
    @StateObject private var modeManager = ARModeManager()
    @State private var selectedLandmark: Landmark?
    @State private var showingDetail: Bool = false
    
    var body: some View {
        ZStack {
            ARViewContainer(
                landmarks: displayedLandmarks,
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
                Image(systemName: modeManager.currentMode.icon)
                Text(modeManager.currentMode.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            
            Spacer()
            
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
            
            HStack(spacing: 4) {
                Image(systemName: "building.2.fill")
                Text("\(displayedLandmarks.count)")
            }
            .font(.subheadline)
            .fontWeight(.medium)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .cornerRadius(20)
        }
    }
    
    private func landmarkInfoCard(_ landmark: Landmark) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(landmark.name)
                        .font(.headline)
                    
                    if let category = landmark.category {
                        HStack(spacing: 4) {
                            Text(category.icon ?? "📍")
                            Text(category.name)
                                .font(.subheadline)
                                .foregroundColor(Color(hex: category.color))
                        }
                    }
                }
                
                Spacer()
                
                if let distance = modeManager.locationService.distance(to: landmark) {
                    Text(formatDistance(distance))
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            if let description = landmark.description {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: 16) {
                if let year = landmark.yearBuilt {
                    Label("\(year)", systemImage: "calendar")
                        .font(.caption)
                }
                
                if let architect = landmark.architect {
                    Label(architect, systemImage: "person.fill")
                        .font(.caption)
                }
            }
            .foregroundColor(.secondary)
            
            Button {
                selectedLandmark = landmark
                showingDetail = true
            } label: {
                Text("Mehr erfahren")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
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
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        if let category = landmark.category {
                            HStack {
                                Text(category.icon ?? "📍")
                                Text(category.name)
                                    .font(.subheadline)
                                    .foregroundColor(Color(hex: category.color))
                            }
                        }
                        
                        Text(landmark.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                    
                    if let weather = weather {
                        weatherCard(weather)
                    }
                    
                    if let description = landmark.description {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Beschreibung")
                                .font(.headline)
                            Text(description)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    detailsGrid
                    
                    coordinatesCard
                    
                    if let url = landmark.wikipediaUrl, let wikipediaURL = URL(string: url) {
                        Link(destination: wikipediaURL) {
                            HStack {
                                Image(systemName: "book.fill")
                                Text("Wikipedia öffnen")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func weatherCard(_ weather: Weather) -> some View {
        HStack {
            Text(weather.iconEmoji)
                .font(.system(size: 40))
            
            VStack(alignment: .leading) {
                Text(weather.temperatureFormatted)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(weather.description.capitalized)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("Gefühlt \(Int(weather.feelsLike))°")
                Text("Luftfeuchtigkeit \(weather.humidity)%")
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var detailsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            if let year = landmark.yearBuilt {
                detailItem(icon: "calendar", title: "Baujahr", value: "\(year)")
            }
            
            if let architect = landmark.architect {
                detailItem(icon: "person.fill", title: "Architekt", value: architect)
            }
            
            detailItem(icon: "arrow.up", title: "Höhe", value: "\(Int(landmark.altitude)) m ü.M.")
        }
    }
    
    private func detailItem(icon: String, title: String, value: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var coordinatesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Koordinaten")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Latitude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.6f°", landmark.latitude))
                        .font(.system(.body, design: .monospaced))
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Longitude")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.6f°", landmark.longitude))
                        .font(.system(.body, design: .monospaced))
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
