//
//  Landmark.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import Foundation

struct Category: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let nameEn: String?
    let icon: String?
    let color: String
    let sortOrder: Int
    
    enum CodingKeys: String, CodingKey {
        case id, name, icon, color
        case nameEn = "name_en"
        case sortOrder = "sort_order"
    }
}

struct Landmark: Codable, Identifiable, Sendable {
    let id: String
    let name: String
    let nameEn: String?
    let description: String?
    let descriptionEn: String?
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let yearBuilt: Int?
    let architect: String?
    let categoryId: String?
    let imageUrl: String?
    let wikipediaUrl: String?
    let isActive: Bool
    let createdAt: String
    let updatedAt: String
    let category: Category?
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, latitude, longitude, altitude, architect, category
        case nameEn = "name_en"
        case descriptionEn = "description_en"
        case yearBuilt = "year_built"
        case categoryId = "category_id"
        case imageUrl = "image_url"
        case wikipediaUrl = "wikipedia_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
