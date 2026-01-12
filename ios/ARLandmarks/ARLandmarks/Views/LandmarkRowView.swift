//
//  LandmarkRowView.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import SwiftUI

struct LandmarkRowView: View {
    let landmark: Landmark
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: landmark.category?.color ?? "#3B82F6").opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Text(landmark.category?.icon ?? "📍")
                    .font(.system(size: 20))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(landmark.name)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    if let category = landmark.category {
                        Text(category.name)
                            .font(.system(size: 13))
                            .foregroundColor(Color(hex: category.color))
                    }
                    
                    Text("•")
                        .foregroundColor(.secondary.opacity(0.5))
                    
                    Text(landmark.yearBuilt != nil ? "\(landmark.yearBuilt!)" : "Unbekannt")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary.opacity(0.5))
        }
        .padding(.vertical, 8)
    }
}
