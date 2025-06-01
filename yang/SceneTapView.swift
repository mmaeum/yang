import SwiftUI
import SceneKit
import Photos
import UIKit

struct SceneTapView: UIViewRepresentable {
    let scene: SCNScene
    @Binding var stars: [Star]
    @State private var isTransitioning = false
    
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
        Coordinator(stars: $stars, isTransitioning: $isTransitioning)
    }
    
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @Binding var stars: [Star]
        @Binding var isTransitioning: Bool
        
        init(stars: Binding<[Star]>, isTransitioning: Binding<Bool>) {
            _stars = stars
            _isTransitioning = isTransitioning
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard
                !self.isTransitioning,
                let scnView = gesture.view as? SCNView,
                let hit = scnView.hitTest(gesture.location(in: scnView), options: nil).first,
                hit.node.geometry is SCNSphere,
                let starId = hit.node.name,
                let star = stars.first(where: { $0.id.uuidString == starId }),
                let root = scnView.window?.rootViewController
            else { return }
            
            self.isTransitioning = true
            
            // 로딩 화면 표시
            let loadingVC = UIHostingController(rootView: LoadingView())
            loadingVC.view.backgroundColor = .clear
            loadingVC.modalPresentationStyle = .overFullScreen
            root.present(loadingVC, animated: false)
            
            let infoView = StarInfoView(star: star)
            let vc = UIHostingController(rootView: infoView)
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            
            // 현재 표시된 모달 뷰가 있다면 닫고 새로운 뷰를 표시
            if let presentedVC = root.presentedViewController {
                presentedVC.dismiss(animated: false) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        root.present(vc, animated: true)
                        // 로딩 화면 제거
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            self.isTransitioning = false
                        }
                    }
                }
            } else {
                root.present(vc, animated: true)
                // 로딩 화면 제거
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.isTransitioning = false
                }
            }
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
