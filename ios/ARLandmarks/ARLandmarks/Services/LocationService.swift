//
//  LocationService.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 13.01.2026.
//

import CoreLocation
import Combine

// MARK: - Thread-safe Heading Model

struct HeadingData: Sendable {
    let trueHeading: Double
    let magneticHeading: Double
    let accuracy: Double
    let timestamp: Date
    
    nonisolated init(from heading: CLHeading) {
        self.trueHeading = heading.trueHeading
        self.magneticHeading = heading.magneticHeading
        self.accuracy = heading.headingAccuracy
        self.timestamp = heading.timestamp
    }
}

// MARK: - Location Service

@MainActor
class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var currentHeading: HeadingData?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var error: String?
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.headingFilter = 5
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func distance(to landmark: Landmark) -> Double? {
        guard let location = currentLocation else { return nil }
        let landmarkLocation = CLLocation(
            latitude: landmark.latitude,
            longitude: landmark.longitude
        )
        return location.distance(from: landmarkLocation)
    }
    
    func bearing(to landmark: Landmark) -> Double? {
        guard let location = currentLocation else { return nil }
        return location.bearing(
            to: CLLocation(latitude: landmark.latitude, longitude: landmark.longitude)
        )
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.currentLocation = location
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let headingData = HeadingData(from: newHeading)
        Task { @MainActor in
            self.currentHeading = headingData
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        let errorMessage = error.localizedDescription
        Task { @MainActor in
            self.error = errorMessage
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.startUpdating()
            }
        }
    }
}

// MARK: - CLLocation Extension

extension CLLocation {
    func bearing(to destination: CLLocation) -> Double {
        let lat1 = self.coordinate.latitude.toRadians
        let lon1 = self.coordinate.longitude.toRadians
        let lat2 = destination.coordinate.latitude.toRadians
        let lon2 = destination.coordinate.longitude.toRadians
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        let bearing = atan2(y, x)
        return bearing.toDegrees.normalizedDegrees
    }
}

// MARK: - Angle Conversions

extension Double {
    var toRadians: Double { self * .pi / 180 }
    var toDegrees: Double { self * 180 / .pi }
    var normalizedDegrees: Double {
        var degrees = self.truncatingRemainder(dividingBy: 360)
        if degrees < 0 { degrees += 360 }
        return degrees
    }
}
