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

        print("🏛️ Landmarks gesetzt: \(landmarks.count)")

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
            print("❌ Location Error: \(error.localizedDescription)")
        }

        // MARK: - POI Management

        private func updatePOIs() {
            guard let arView = arView,
                  let userLocation = currentLocation else {
                print("⚠️ Keine Location verfügbar")
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
            print("🔍 Suche Landmarks in der Nähe von: \(userLocation.coordinate.latitude), \(userLocation.coordinate.longitude)")
            print("🔍 Anzahl allLandmarks: \(landmarks.count)")

            let nearbyLandmarks = landmarks.filter { landmark in
                let landmarkLocation = CLLocation(
                    latitude: landmark.latitude,
                    longitude: landmark.longitude
                )
                let distance = userLocation.distance(from: landmarkLocation)
                print("   \(landmark.name): \(Int(distance))m")
                return distance <= radius
            }

            print("✅ Nearby Landmarks gefunden: \(nearbyLandmarks.count)")
            return nearbyLandmarks
        }

        private func placePOI(for landmark: Landmark, userLocation: CLLocation, in arView: ARView) {
            let landmarkLocation = CLLocation(
                latitude: landmark.latitude,
                longitude: landmark.longitude
            )

            let distance = userLocation.distance(from: landmarkLocation)
            let bearing = calculateBearing(from: userLocation, to: landmarkLocation)

            // Scale distance for AR visualization
            // Closer POIs (< 500m): place at 2-4m in AR
            // Far POIs (> 500m): place at 4-6m in AR
            let arDistance: Float
            if distance < 100 {
                arDistance = 2.0 + Float(distance / 100) * 1.0  // 2-3m
            } else if distance < 500 {
                arDistance = 3.0 + Float((distance - 100) / 400) * 1.5  // 3-4.5m
            } else {
                arDistance = 4.5 + min(Float((distance - 500) / 1500) * 1.5, 1.5)  // 4.5-6m
            }

            // Calculate AR position using bearing
            let x = arDistance * Float(sin(bearing))
            let z = -arDistance * Float(cos(bearing))

            // Height: eye level
            let y: Float = 0.0

            let position = SIMD3<Float>(x, y, z)

            let anchorEntity = AnchorEntity(world: position)

            // Create Apple Maps-style balloon marker
            let markerEntity = createBalloonMarker(for: landmark)
            markerEntity.name = landmark.id
            markerEntity.generateCollisionShapes(recursive: true)

            anchorEntity.addChild(markerEntity)
            arView.scene.addAnchor(anchorEntity)

            print("📍 POI erstellt: \(landmark.name) at \(position) with ID \(landmark.id)")
        }

        private func createBalloonMarker(for landmark: Landmark) -> Entity {
            let markerEntity = Entity()
            let color = UIColor(Color(hex: landmark.category?.color ?? "#3B82F6"))

            // Balloon body (circular top part)
            let balloonRadius: Float = 0.12
            let balloonMesh = MeshResource.generateSphere(radius: balloonRadius)
            let balloonMaterial = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            let balloonEntity = ModelEntity(mesh: balloonMesh, materials: [balloonMaterial])
            balloonEntity.position = SIMD3<Float>(0, balloonRadius + 0.08, 0)

            // Inner circle (white background for icon)
            let innerRadius: Float = 0.08
            let innerMesh = MeshResource.generateSphere(radius: innerRadius)
            let innerMaterial = SimpleMaterial(color: .white, roughness: 0.5, isMetallic: false)
            let innerEntity = ModelEntity(mesh: innerMesh, materials: [innerMaterial])
            innerEntity.position = SIMD3<Float>(0, 0, balloonRadius * 0.6)
            balloonEntity.addChild(innerEntity)

            // Category icon as text
            let iconText = landmark.category?.icon ?? "📍"
            let iconMesh = MeshResource.generateText(
                iconText,
                extrusionDepth: 0.005,
                font: .systemFont(ofSize: 0.06),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byClipping
            )
            let iconMaterial = SimpleMaterial(color: .black, isMetallic: false)
            let iconEntity = ModelEntity(mesh: iconMesh, materials: [iconMaterial])
            iconEntity.position = SIMD3<Float>(-0.025, -0.025, innerRadius * 0.9)
            innerEntity.addChild(iconEntity)

            // Pointer/tip at bottom (small cone shape using a thin box)
            let pointerHeight: Float = 0.08
            let pointerMesh = MeshResource.generateCone(height: pointerHeight, radius: 0.03)
            let pointerMaterial = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            let pointerEntity = ModelEntity(mesh: pointerMesh, materials: [pointerMaterial])
            // Rotate cone to point downward and position below balloon
            pointerEntity.orientation = simd_quatf(angle: .pi, axis: SIMD3<Float>(1, 0, 0))
            pointerEntity.position = SIMD3<Float>(0, 0, 0)

            // Text label below marker
            let textMesh = MeshResource.generateText(
                landmark.name,
                extrusionDepth: 0.008,
                font: .systemFont(ofSize: 0.05, weight: .semibold),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])

            // Calculate text width for centering
            let textBounds = textMesh.bounds
            let textWidth = textBounds.max.x - textBounds.min.x
            textEntity.position = SIMD3<Float>(-textWidth / 2, -0.15, 0)

            // Add shadow/background for text readability
            let bgMesh = MeshResource.generateBox(
                width: textWidth + 0.04,
                height: 0.07,
                depth: 0.005,
                cornerRadius: 0.02
            )
            let bgMaterial = SimpleMaterial(color: UIColor.black.withAlphaComponent(0.6), roughness: 1.0, isMetallic: false)
            let bgEntity = ModelEntity(mesh: bgMesh, materials: [bgMaterial])
            bgEntity.position = SIMD3<Float>(0, -0.12, -0.01)

            markerEntity.addChild(balloonEntity)
            markerEntity.addChild(pointerEntity)
            markerEntity.addChild(bgEntity)
            markerEntity.addChild(textEntity)

            return markerEntity
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

            print("👆 Tap at: \(location)")

            let hits = arView.hitTest(location)
            print("👆 Hits: \(hits.count)")

            if let firstHit = hits.first {
                let entityName = firstHit.entity.name
                print("👆 Hit entity name: '\(entityName)'")

                // Find landmark by ID
                print("📋 Verfügbare Landmarks: \(landmarks.map { $0.id })")

                if let landmark = landmarks.first(where: { $0.id == entityName }) {
                    print("✅ Found landmark: \(landmark.name)")
                    DispatchQueue.main.async {
                        self.parent.selectedLandmark = landmark
                    }
                } else {
                    print("❌ Kein Landmark gefunden für ID: \(entityName)")
                }
            } else {
                // Tap on empty space - deselect
                print("👆 Tap auf leeren Bereich - Auswahl aufheben")
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
