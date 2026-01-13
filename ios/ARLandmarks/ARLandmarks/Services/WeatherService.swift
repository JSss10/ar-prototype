//
//  WeatherService.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 13.01.2026.
//

import Foundation

actor WeatherService {
    static let shared = WeatherService()

    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"
    private var cache: [String: (weather: Weather, timestamp: Date)] = [:]
    private let cacheValiditySeconds: TimeInterval = 600 // 10 Minuten

    private init() {
        self.apiKey = (Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_API_KEY") as? String) ?? ""
    }

    func fetchWeather(latitude: Double, longitude: Double) async throws -> Weather {
        guard !apiKey.isEmpty else { throw WeatherError.missingAPIKey }

        let cacheKey = "\(latitude),\(longitude)"

        if let cached = cache[cacheKey],
           Date().timeIntervalSince(cached.timestamp) < cacheValiditySeconds {
            return cached.weather
        }

        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "lang", value: "de")
        ]

        guard let url = components?.url else { throw WeatherError.invalidURL }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw WeatherError.networkError(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw WeatherError.invalidResponse
        }

        let weatherResponse = try await MainActor.run {
            try JSONDecoder().decode(WeatherResponse.self, from: data)
        }

        let weather = Weather(
            temperature: weatherResponse.main.temp,
            feelsLike: weatherResponse.main.feelsLike,
            humidity: weatherResponse.main.humidity,
            condition: weatherResponse.weather.first?.main ?? "",
            description: weatherResponse.weather.first?.description ?? "",
            icon: weatherResponse.weather.first?.icon ?? ""
        )

        cache[cacheKey] = (weather, Date())
        return weather
    }

    func fetchZurichWeather() async throws -> Weather {
        try await fetchWeather(latitude: 47.3769, longitude: 8.5417)
    }
}
