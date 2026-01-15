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
                
                trackingStatusView
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
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white, .black.opacity(0.3))
            }
            
            Spacer()
            
            Text("\(landmarks.count) Landmarks")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.black.opacity(0.3))
                .clipShape(Capsule())
        }
        .padding()
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
    
    private var trackingStatusView: some View {
        HStack {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            Text("AR aktiv")
                .font(.system(size: 12))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.5))
        .clipShape(Capsule())
        .padding(.bottom, 8)
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
