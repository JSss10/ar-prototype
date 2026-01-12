//
//  SupabaseService.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import Foundation

struct SupabaseService: Sendable {
    static let shared = SupabaseService()
    
    private let baseURL: String
    private let apiKey: String
    
    private init() {
        self.baseURL = Config.supabaseURL
        self.apiKey = Config.supabaseAnonKey
    }
    
    // MARK: - Public Methods
    
    func fetchLandmarks() async throws -> [Landmark] {
        let query = "select=*,category:categories(*)&is_active=eq.true&order=name.asc"
        return try await request(path: "landmarks", query: query)
    }
    
    func fetchCategories() async throws -> [Category] {
        let query = "select=*&order=sort_order.asc"
        return try await request(path: "categories", query: query)
    }
    
    // MARK: - Private Methods
    
    private func request<T: Decodable>(path: String, query: String) async throws -> T {
        guard let url = URL(string: "\(baseURL)/rest/v1/\(path)?\(query)") else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.httpError(httpResponse.statusCode)
        }
        
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    }
}

// MARK: - API Errors

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case notFound
    case decodingError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ungültige URL"
        case .invalidResponse:
            return "Ungültige Server-Antwort"
        case .httpError(let code):
            return "HTTP Fehler: \(code)"
        case .notFound:
            return "Nicht gefunden"
        case .decodingError(let message):
            return "Dekodierungsfehler: \(message)"
        }
    }
}
