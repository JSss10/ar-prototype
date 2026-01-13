//
//  WeatherModels.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 13.01.2026.
//

import Foundation

// MARK: - API Response Models

struct WeatherResponse: Codable, Sendable {
    let main: WeatherMain
    let weather: [WeatherCondition]
    let name: String
}

struct WeatherMain: Codable, Sendable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    
    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
    }
}

struct WeatherCondition: Codable, Sendable {
    let id: Int
    let main: String
    let description: String
    let icon: String
}

// MARK: - App Weather Model

struct Weather: Equatable, Sendable {
    let temperature: Double
    let feelsLike: Double
    let humidity: Int
    let condition: String
    let description: String
    let icon: String
    
    var iconEmoji: String {
        switch icon.prefix(2) {
        case "01": return "☀️"
        case "02": return "🌤️"
        case "03": return "☁️"
        case "04": return "☁️"
        case "09": return "🌧️"
        case "10": return "🌦️"
        case "11": return "⛈️"
        case "13": return "🌨️"
        case "50": return "🌫️"
        default: return "🌡️"
        }
    }
    
    var temperatureFormatted: String {
        "\(Int(round(temperature)))°C"
    }
}

// MARK: - Weather Error

enum WeatherError: Error, LocalizedError, Sendable {
    case invalidURL
    case networkError(String)
    case invalidResponse
    case decodingError(String)
    case missingAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Ungültige URL"
        case .networkError(let message): return "Netzwerkfehler: \(message)"
        case .invalidResponse: return "Ungültige Antwort vom Server"
        case .decodingError(let message): return "Dekodierungsfehler: \(message)"
        case .missingAPIKey: return "OpenWeather API Key fehlt"
        }
    }
}

