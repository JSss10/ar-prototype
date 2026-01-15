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
        
        // Komprimiert echte Distanzen auf AR-Distanzen
        let arDistance = scaleDistanceForAR(distance)
        
        // AR-Koordinaten
        let x = Float(arDistance * sin(relativeBearing))
        let z = Float(-arDistance * cos(relativeBearing))
        
        let altitudeDiff = landmark.altitude - userLocation.altitude
        let scaledHeight = Float(altitudeDiff / 500)
        let y = max(-0.5, min(1.5, scaledHeight)) + 0.3
        
        return SIMD3<Float>(x, y, z)
    }
    
    /// Skaliert echte Distanz auf AR-Distanz
    private static func scaleDistanceForAR(_ meters: Double) -> Double {
        if meters < 100 {
            // Nah (0-100m): 2-3m in AR
            return 2.0 + (meters / 100.0) * 1.0
        } else if meters < 500 {
            // Mittel (100-500m): 3-4.5m in AR
            return 3.0 + ((meters - 100) / 400.0) * 1.5
        } else {
            // Weit (500m+): 4.5-6m in AR (max 6m)
            return 4.5 + min((meters - 500) / 1500.0 * 1.5, 1.5)
        }
    }
    
    /// Berechnet ob ein Landmark im Sichtfeld ist
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
