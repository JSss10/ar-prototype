//
//  ARPositionCalculator.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 13.01.2026.
//

import CoreLocation
import simd

struct ARPositionCalculator {
    
    /// Berechnet AR-Position relativ zum Benutzer
    /// - landmark: Ziel-Landmark
    /// - userLocation: Aktuelle GPS-Position
    /// - userHeading: Aktuelle Kompass-Richtung (in Grad, 0 = Nord)
    static func calculatePosition(
        for landmark: Landmark,
        userLocation: CLLocation,
        userHeading: Double
    ) -> SIMD3<Float> {
        let landmarkLocation = CLLocation(
            latitude: landmark.latitude,
            longitude: landmark.longitude
        )
        
        // Distanz in Metern
        let distance = userLocation.distance(from: landmarkLocation)
        
        // Bearing zum Landmark (0° = Nord)
        let bearing = userLocation.bearing(to: landmarkLocation)
        
        // Relative Richtung (berücksichtigt wohin User schaut)
        let relativeBearing = (bearing - userHeading).toRadians
        
        // AR verwendet: +X = rechts, +Y = oben, -Z = vorwärts
        // Skalierung: 1 Meter GPS = 1 Meter AR (für nahe Objekte)
        // Für weite Distanzen: logarithmische Skalierung
        let scaledDistance = scaleDistance(distance)
        
        let x = Float(scaledDistance * sin(relativeBearing))
        let z = Float(-scaledDistance * cos(relativeBearing))
        
        // Höhendifferenz
        let y = Float(landmark.altitude - userLocation.altitude)
        
        return SIMD3<Float>(x, y, z)
    }
    
    /// Skaliert Distanz für bessere AR-Darstellung
    private static func scaleDistance(_ meters: Double) -> Double {
        let maxARDistance: Double = 50 // in Metern
        
        if meters <= maxARDistance {
            return meters
        }
        
        // Logarithmische Skalierung für weite Distanzen
        let factor: Double = 10
        return maxARDistance + log(meters - maxARDistance + 1) * factor
    }
    
    /// Berechnet ob ein Landmark im Sichtfeld ist
    /// - Parameters:
    ///   - landmark: Das Landmark
    ///   - userLocation: Benutzer-Position
    ///   - userHeading: Blickrichtung
    ///   - fieldOfView: Sichtfeld in Grad (Standard: 60°)
    static func isInFieldOfView(
        landmark: Landmark,
        userLocation: CLLocation,
        userHeading: Double,
        fieldOfView: Double = 60
    ) -> Bool {
        let landmarkLocation = CLLocation(
            latitude: landmark.latitude,
            longitude: landmark.longitude
        )
        let bearing = userLocation.bearing(to: landmarkLocation)
        
        var angleDifference = abs(bearing - userHeading)
        if angleDifference > 180 {
            angleDifference = 360 - angleDifference
        }
        
        return angleDifference <= fieldOfView / 2
    }
}
