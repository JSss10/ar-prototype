//
//  CLLocation+Extensions.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 13.01.2026.
//

import CoreLocation

// MARK: - CLLocation Extension

extension CLLocation {
    /// - Parameter destination: Ziel-Location
    /// - Returns: Bearing in Grad (0-360, 0 = Nord)
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
