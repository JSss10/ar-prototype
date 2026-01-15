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
    @State private var selectedLandmark: Landmark?
    @State private var showingDetail = false
    @State private var isGeoMode = true
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ARViewContainer(landmarks: landmarks, selectedLandmark: $selectedLandmark)
                .ignoresSafeArea()

            VStack {
                headerView

                Spacer()

                if let landmark = selectedLandmark {
                    landmarkInfoCard(landmark)
                }

                modeSwitcher
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let landmark = selectedLandmark {
                LandmarkDetailSheet(landmark: landmark)
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack(spacing: 8) {
            // Geo-basierte POIs pill
            HStack(spacing: 6) {
                Image(systemName: "location.north.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.green)

                Text("Geo-basierte POIs")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(Capsule())

            Spacer()

            // Weather info
            HStack(spacing: 4) {
                Text("☀️")
                    .font(.system(size: 14))
                Text("10°C")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(Capsule())

            // Landmarks count
            HStack(spacing: 4) {
                Image(systemName: "mappin.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
                Text("\(landmarks.count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.regularMaterial)
            .clipShape(Capsule())

            // Close button
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white, .black.opacity(0.5))
            }
        }
        .padding()
    }

    private var modeSwitcher: some View {
        HStack(spacing: 0) {
            // Vision mode button
            Button {
                isGeoMode = false
            } label: {
                Image(systemName: "eye")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(isGeoMode ? .primary : .white)
                    .frame(width: 44, height: 36)
                    .background(isGeoMode ? Color.clear : Color.blue)
                    .clipShape(Capsule())
            }

            // Geo mode button
            Button {
                isGeoMode = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "location.north.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Geo-basierte POIs")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(isGeoMode ? .white : .primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isGeoMode ? Color.blue : Color.clear)
                .clipShape(Capsule())
            }
        }
        .padding(4)
        .background(.regularMaterial)
        .clipShape(Capsule())
        .padding(.bottom, 8)
    }
    
    private func landmarkInfoCard(_ landmark: Landmark) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 12) {
                // Icon with colored background
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
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                }
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
    
}

// MARK: - Landmark Detail Sheet

struct LandmarkDetailSheet: View {
    let landmark: Landmark
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
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
            .navigationTitle("Details")
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
