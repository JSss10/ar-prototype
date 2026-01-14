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
        config.planeDetection = [.horizontal]
        config.environmentTexturing = .automatic
        config.worldAlignment = .gravityAndHeading
        
        arView.session.delegate = context.coordinator
        arView.session.run(config)
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        context.coordinator.arView = arView
        
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {
        context.coordinator.updateLandmarks(landmarks, in: arView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, ARSessionDelegate {
        var parent: ARViewContainer
        weak var arView: ARView?
        private var landmarkEntities: [String: AnchorEntity] = [:]
        private var currentLandmarkIDs: Set<String> = []
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        func updateLandmarks(_ landmarks: [Landmark], in arView: ARView) {
            let newLandmarkIDs = Set(landmarks.map { $0.id })
            
            for id in currentLandmarkIDs.subtracting(newLandmarkIDs) {
                if let anchor = landmarkEntities[id] {
                    arView.scene.removeAnchor(anchor)
                    landmarkEntities.removeValue(forKey: id)
                }
            }
            
            guard let userLocation = parent.modeManager.locationService.currentLocation,
                  let userHeading = parent.modeManager.locationService.currentHeading?.trueHeading else {
                // Fallback – Demo Position
                addDemoAnchors(landmarks, to: arView)
                return
            }
            
            for landmark in landmarks where !currentLandmarkIDs.contains(landmark.id) {
                let position = ARPositionCalculator.calculatePosition(
                    for: landmark,
                    userLocation: userLocation,
                    userHeading: userHeading
                )
                
                let anchor = createLandmarkAnchor(for: landmark, at: position)
                arView.scene.addAnchor(anchor)
                landmarkEntities[landmark.id] = anchor
            }
            
            currentLandmarkIDs = newLandmarkIDs
        }
        
        private func createLandmarkAnchor(for landmark: Landmark, at position: SIMD3<Float>) -> AnchorEntity {
            let anchor = AnchorEntity(world: position)
            
            let color = UIColor(Color(hex: landmark.category?.color ?? "#3B82F6"))
            let sphere = MeshResource.generateSphere(radius: 0.15)
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
            sphereEntity.name = landmark.id
            sphereEntity.generateCollisionShapes(recursive: false)
            
            // Pulsing Animation
            if parent.modeManager.currentMode == .visualRecognition {
                let pulseScale: Float = 1.3
                sphereEntity.scale = SIMD3<Float>(repeating: pulseScale)
            }
            
            let textMesh = MeshResource.generateText(
                landmark.name,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.06, weight: .bold),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            textEntity.position = SIMD3<Float>(0, 0.25, 0)
            
            if let distance = parent.modeManager.locationService.distance(to: landmark) {
                let distanceText = distance < 1000
                    ? "\(Int(distance))m"
                    : String(format: "%.1fkm", distance/1000)
                let distanceMesh = MeshResource.generateText(
                    distanceText,
                    extrusionDepth: 0.005,
                    font: .systemFont(ofSize: 0.04),
                    containerFrame: .zero,
                    alignment: .center,
                    lineBreakMode: .byClipping
                )
                let distanceEntity = ModelEntity(mesh: distanceMesh, materials: [textMaterial])
                distanceEntity.position = SIMD3<Float>(0, 0.35, 0)
                anchor.addChild(distanceEntity)
            }
            
            anchor.addChild(sphereEntity)
            anchor.addChild(textEntity)
            
            return anchor
        }

        private func addDemoAnchors(_ landmarks: [Landmark], to arView: ARView) {
            for (index, landmark) in landmarks.enumerated() {
                guard !currentLandmarkIDs.contains(landmark.id) else { continue }
                
                let angle = (Double(index) / Double(max(landmarks.count, 1))) * 2 * .pi
                let distance: Float = 3.0
                
                let x = Float(cos(angle)) * distance
                let z = Float(sin(angle)) * -distance
                let position = SIMD3<Float>(x, 0, z)
                
                let anchor = createLandmarkAnchor(for: landmark, at: position)
                arView.scene.addAnchor(anchor)
                landmarkEntities[landmark.id] = anchor
            }
            currentLandmarkIDs = Set(landmarks.map { $0.id })
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)
            
            if let entity = arView.entity(at: location) {
                let id = entity.name
                if let landmark = parent.landmarks.first(where: { $0.id == id }) {
                    parent.selectedLandmark = landmark
                }
            }
        }
        
        // MARK: - ARSessionDelegate
        
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            /*
            Task { @MainActor in
                let result = await parent.modeManager.visionService.classifyImage(frame.capturedImage)
                if let result = result {
                    parent.modeManager.handleRecognition(result, landmarks: parent.landmarks)
                } else {
                    parent.modeManager.handleNoRecognition()
                }
            }
            */
        }
    }
}
