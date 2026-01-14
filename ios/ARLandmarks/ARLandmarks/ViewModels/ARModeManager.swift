//
//  ARModeManager.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 14.01.2026.
//

import SwiftUI
import Combine
import CoreLocation

@MainActor
class ARModeManager: ObservableObject {
    
    // MARK: - AR Mode
    
    enum ARMode: String, CaseIterable {
        case visualRecognition = "Visuelle Erkennung"
        case geoBased = "Geo-basierte POIs"
        
        var icon: String {
            switch self {
            case .visualRecognition: return "eye.fill"
            case .geoBased: return "location.fill"
            }
        }
        
        var description: String {
            switch self {
            case .visualRecognition:
                return "Richte die Kamera auf eine Sehenswürdigkeit"
            case .geoBased:
                return "Zeigt umliegende POIs basierend auf GPS"
            }
        }
    }
    
    // MARK: - Published Properties
    
    @Published var currentMode: ARMode = .visualRecognition
    @Published var recognizedLandmark: Landmark?
    @Published var nearbyLandmarks: [Landmark] = []
    @Published var weather: Weather?
    @Published var isLoading: Bool = false
    @Published var statusMessage: String = "Bereit"
    
    // MARK: - Services
    
    let locationService = LocationService()
    let visionService = VisionService()
    private let weatherService = WeatherService.shared
    
    // MARK: - Settings
    
    /// Maximale Distanz für Geo-POIs in Metern
    let maxPOIDistance: Double = 2000
    
    /// Zeit ohne Erkennung bevor Fallback aktiviert wird
    let recognitionTimeout: TimeInterval = 5.0
    
    private var lastRecognitionTime: Date = Date()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupBindings()
    }
    
    private func setupBindings() {
        locationService.$currentLocation
            .compactMap { $0 }
            .debounce(for: .seconds(1), scheduler: DispatchQueue.main)
            .sink { [weak self] location in
                self?.updateNearbyLandmarks()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func startSession() {
        locationService.requestPermission()
        fetchWeather()
    }
    
    func stopSession() {
        locationService.stopUpdating()
    }
    
    func handleRecognition(_ result: RecognitionResult, landmarks: [Landmark]) {
        lastRecognitionTime = Date()
        
        if currentMode != .visualRecognition {
            currentMode = .visualRecognition
        }
        
        if let landmarkID = result.landmarkID,
           let landmark = landmarks.first(where: { $0.id == landmarkID }) {
            recognizedLandmark = landmark
            statusMessage = "\(landmark.name) erkannt (\(result.confidencePercent)%)"
        }
    }
    
    func handleNoRecognition() {
        let timeSinceLastRecognition = Date().timeIntervalSince(lastRecognitionTime)
        
        if timeSinceLastRecognition > recognitionTimeout && currentMode == .visualRecognition {
            // Fallback Geo-Mode
            switchToGeoMode()
        }
    }
    
    func switchToGeoMode() {
        currentMode = .geoBased
        recognizedLandmark = nil
        statusMessage = "Geo-Modus aktiv"
        updateNearbyLandmarks()
    }
    
    func switchToVisualMode() {
        currentMode = .visualRecognition
        lastRecognitionTime = Date()
        statusMessage = "Suche Sehenswürdigkeiten..."
    }
    
    func updateNearbyLandmarks(allLandmarks: [Landmark] = []) {
        guard let location = locationService.currentLocation else { return }
        
        nearbyLandmarks = allLandmarks
            .filter { landmark in
                let landmarkLocation = CLLocation(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                )
                return location.distance(from: landmarkLocation) <= maxPOIDistance
            }
            .sorted { landmark1, landmark2 in
                let loc1 = CLLocation(latitude: landmark1.latitude, longitude: landmark1.longitude)
                let loc2 = CLLocation(latitude: landmark2.latitude, longitude: landmark2.longitude)
                return location.distance(from: loc1) < location.distance(from: loc2)
            }
    }
    
    /// Aktuelle Wetterdaten
    func fetchWeather() {
        Task {
            do {
                let fetchedWeather = try await weatherService.fetchZurichWeather()
                self.weather = fetchedWeather
            } catch {
                print("Weather error: \(error.localizedDescription)")
            }
        }
    }
}
