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
        switch icon {
        case "01d": return "☀️"
        case "01n": return "✨"
        case "02d": return "🌤️"
        case "02n": return "✨"
        case "03d": return "☁️"
        case "03n": return "✨"
        case "04d": return "☁️"
        case "04n": return "✨"
        case "09d": return "🌧️"
        case "09n": return "✨"
        case "10d": return "🌦️"
        case "10n": return "✨"
        case "11d": return "⛈️"
        case "11n": return "✨"
        case "13d": return "🌨️"
        case "13n": return "✨"
        case "50d": return "🌫️"
        case "50n": return "✨"
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

