import SwiftUI
import SceneKit
import Photos

struct SceneTapView: UIViewRepresentable {
    let scene: SCNScene
    @Binding var stars: [Star]
    
    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true
        
        // 탭 제스처
        let tap = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleTap(_:))
        )
        tap.delegate = context.coordinator
        scnView.addGestureRecognizer(tap)
        
        // 핀치 제스처(줌)
        let pinch = UIPinchGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePinch(_:))
        )
        pinch.delegate = context.coordinator
        scnView.addGestureRecognizer(pinch)
        
        return scnView
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {
        // Star 객체가 추가될 때마다 씬에 노드 추가
        for star in stars {
            if scene.rootNode.childNode(withName: star.id.uuidString, recursively: false) == nil {
                let node = createStarNode(for: star)
                scene.rootNode.addChildNode(node)
            }
        }
    }
    
    private func createStarNode(for star: Star) -> SCNNode {
        let sphere = SCNSphere(radius: 0.2)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.white
        mat.emission.contents = UIColor.white
        mat.lightingModel = .constant
        sphere.materials = [mat]
        
        let node = SCNNode(geometry: sphere)
        node.name = star.id.uuidString
        node.position = star.position
        return node
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(stars: $stars)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var stars: [Star]
        
        init(stars: Binding<[Star]>) {
            _stars = stars
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard
                let scnView = gesture.view as? SCNView,
                let hit = scnView.hitTest(gesture.location(in: scnView), options: nil).first,
                hit.node.geometry is SCNSphere,
                let starId = hit.node.name,
                let star = stars.first(where: { $0.id.uuidString == starId }),
                let root = scnView.window?.rootViewController
            else { return }
            
            let infoView = StarInfoView(star: star)
            let vc = UIHostingController(rootView: infoView)
            vc.modalPresentationStyle = .fullScreen
            root.present(vc, animated: true)
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            guard
                let scnView = gesture.view as? SCNView,
                let cameraNode = scnView.scene?.rootNode.childNodes.first(where: { $0.camera != nil }),
                let camera = cameraNode.camera
            else { return }
            
            let newFOV = camera.fieldOfView / Double(gesture.scale)
            camera.fieldOfView = max(10, min(100, newFOV))
            gesture.scale = 1.0
        }
        
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                              shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer)
        -> Bool { true }
    }
}
