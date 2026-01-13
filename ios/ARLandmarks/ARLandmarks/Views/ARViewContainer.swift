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
        arView.session.run(config)
        
        print("AR Session gestartet")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            addDemoAnchors(to: arView, landmarks: landmarks)
        }
        
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        arView.addGestureRecognizer(tapGesture)
        
        return arView
    }
    
    func updateUIView(_ arView: ARView, context: Context) {

    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func addDemoAnchors(to arView: ARView, landmarks: [Landmark]) {
        for (index, landmark) in landmarks.enumerated() {
  
            let angle = (Double(index) / Double(landmarks.count)) * 2 * .pi
            let distance: Float = 2.5
            
            let x = Float(cos(angle)) * distance
            let z = Float(sin(angle)) * distance * -1
            
            let anchorEntity = AnchorEntity(world: SIMD3<Float>(x, 0, z))
            
            let color = UIColor(Color(hex: landmark.category?.color ?? "#3B82F6"))
            let sphere = MeshResource.generateSphere(radius: 0.12)
            let material = SimpleMaterial(color: color, roughness: 0.3, isMetallic: false)
            let sphereEntity = ModelEntity(mesh: sphere, materials: [material])
            sphereEntity.name = landmark.id
            sphereEntity.generateCollisionShapes(recursive: false)
            
            let textMesh = MeshResource.generateText(
                landmark.name,
                extrusionDepth: 0.01,
                font: .systemFont(ofSize: 0.08, weight: .bold),
                containerFrame: .zero,
                alignment: .center,
                lineBreakMode: .byTruncatingTail
            )
            let textMaterial = SimpleMaterial(color: .white, isMetallic: false)
            let textEntity = ModelEntity(mesh: textMesh, materials: [textMaterial])
            textEntity.position = SIMD3<Float>(0, 0.2, 0)
            
            anchorEntity.addChild(sphereEntity)
            anchorEntity.addChild(textEntity)
            arView.scene.addAnchor(anchorEntity)
            
            print("Landmark hinzugefügt: \(landmark.name) at (\(x), 0, \(z))")
        }
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject {
        var parent: ARViewContainer
        
        init(_ parent: ARViewContainer) {
            self.parent = parent
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let arView = gesture.view as? ARView else { return }
            let location = gesture.location(in: arView)
            
            if let entity = arView.entity(at: location) {
                let name = entity.name
                print("Tapped: \(name)")
                
                if let landmark = parent.landmarks.first(where: { $0.id == name }) {
                    parent.selectedLandmark = landmark
                }
            }
        }
    }
}
