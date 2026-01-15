//
//  ARViewContainer.swift
//  ARLandmarks
//
//  Created by Jessica Schneiter on 12.01.2026.
//

import SwiftUI
import ARKit
import RealityKit
import CoreLocation

struct ARViewContainer: UIViewRepresentable {
    let landmarks: [Landmark]
    @Binding var selectedLandmark: Landmark?
    let modeManager: ARModeManager

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        config.worldAlignment = .gravityAndHeading
        arView.session.run(config)

        context.coordinator.arView = arView
        context.coordinator.landmarks = landmarks
        context.coordinator.startLocationUpdates()

        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)

        print("Landmarks gesetzt: \(landmarks.count)")

        return arView
    }

    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.landmarks = landmarks
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, CLLocationManagerDelegate {
        var parent: ARViewContainer
        var arView: ARView?
        var landmarks: [Landmark] = []
        var placedLandmarkIds: Set<String> = []

        private let locationManager = CLLocationManager()
        private var currentLocation: CLLocation?
        private var currentHeading: CLHeading?

        init(_ parent: ARViewContainer) {
            self.parent = parent
            super.init()

            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.distanceFilter = 5
        }

        func startLocationUpdates() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }

        // MARK: - CLLocationManagerDelegate

        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else { return }
            currentLocation = location

            print("📍 Location Update: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            updatePOIs()
        }

        func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
            currentHeading = newHeading
        }

        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            print("Standort Fehler: \(error.localizedDescription)")
        }

        // MARK: - POI Management

        private func updatePOIs() {
            guard let arView = arView,
                  let userLocation = currentLocation else {
                print("Kein Standort verfügbar")
                return
            }

            let nearbyLandmarks = findNearbyLandmarks(userLocation: userLocation, radius: 2000)

            for landmark in nearbyLandmarks {
                if !placedLandmarkIds.contains(landmark.id) {
                    placePOI(for: landmark, userLocation: userLocation, in: arView)
                    placedLandmarkIds.insert(landmark.id)
                }
            }
        }

        private func findNearbyLandmarks(userLocation: CLLocation, radius: Double) -> [Landmark] {
            print("Suche Landmarks in der Nähe von: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            print("Anzahl allLandmarks: \(landmarks.count)")

            let nearbyLandmarks = landmarks.filter { landmark in
                let landmarkLocation = CLLocation(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                )
                let distance = userLocation.distance(from: landmarkLocation)
                print("   \(landmark.name): \(Int(distance))m")
                return distance <= radius
            }

            print("Nearby Landmarks gefunden: \(nearbyLandmarks.count)")
            return nearbyLandmarks
        }

        private func placePOI(for landmark: Landmark, userLocation: CLLocation, in arView: ARView) {
            let landmarkLocation = CLLocation(
                latitude: landmark.latitude,
                longitude: landmark.longitude
            )

            let distance = userLocation.distance(from: landmarkLocation)
            let bearing = calculateBearing(from: userLocation, to: landmarkLocation)

            let arDistance = min(Float(distance / 100), 10.0)

            let x = arDistance * Float(sin(bearing))
            let z = -arDistance * Float(cos(bearing))

            let y: Float = Float(distance / 5000)

            let position = SIMD3<Float>(x, y, z)

            let anchorEntity = AnchorEntity(world: position)

            let color = UIColor(Color(hex: landmark.category?.color ?? "#3B82F6"))
            let sphere = MeshResource.generateSphere(radius: 0.15)
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphere, materials: [material])

            sphereEntity.name = landmark.id
            sphereEntity.generateCollisionShapes(recursive: false)

            anchorEntity.addChild(sphereEntity)
            arView.scene.addAnchor(anchorEntity)

            print("POI erstellt: \(landmark.name) bei \(position) mit ID \(landmark.id)")
        }

        private func calculateBearing(from: CLLocation, to: CLLocation) -> Double {
            let lat1 = from.coordinate.latitude.degreesToRadians
            let lon1 = from.coordinate.longitude.degreesToRadians
            let lat2 = to.coordinate.latitude.degreesToRadians
            let lon2 = to.coordinate.longitude.degreesToRadians

            let dLon = lon2 - lon1

            let y = sin(dLon) * cos(lat2)
            let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)

            return atan2(y, x)
        }

        // MARK: - Tap Handling

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)

            print("Angeklickt bei: \(location)")

            let hits = arView.hitTest(location)
            print("Treffer: \(hits.count)")

            if let firstHit = hits.first {
                let entityName = firstHit.entity.name
                print("Treffer Objektname: '\(entityName)'")

                print("Verfügbare Wahrzeichen: \(landmarks.map { $0.id })")

                if let landmark = landmarks.first(where: { $0.id == entityName }) {
                    print("Gefundenes Wahrzeichen: \(landmark.name)")
                    DispatchQueue.main.async {
                        self.parent.selectedLandmark = landmark
                    }
                } else {
                    print("Kein Wahrzeichen gefunden für ID: \(entityName)")
                }
            } else {
                print("Klick auf leeren Bereich - Auswahl aufheben")
                DispatchQueue.main.async {
                    self.parent.selectedLandmark = nil
                }
            }
        }
    }
}

// MARK: - Extensions

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}
