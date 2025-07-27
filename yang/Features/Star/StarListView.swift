import SwiftUI
import SceneKit
import Photos
import UIKit

struct StarListView: UIViewRepresentable {
    let scene: SCNScene
    @Binding var stars: [Star]
    @State private var isTransitioning = false

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView(frame: .zero)
        scnView.scene = scene
        scnView.backgroundColor = .black
        scnView.autoenablesDefaultLighting = true  // 조명 활성화
        scnView.allowsCameraControl = true
        
        // 환경 조명 추가로 빛나는 효과 강화
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 0.1
        ambientLight.color = UIColor.white
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        // 탭 제스처 추가
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
        // 씬에 아직 없는 Star 노드만 추가
        for star in stars {
            if scene.rootNode.childNode(withName: star.id, recursively: false) == nil {
                let node = createStarNode(for: star)
                scene.rootNode.addChildNode(node)
            }
        }
    }

    private func createStarNode(for star: Star) -> SCNNode {
        // 밝기에 따라 별의 크기와 색상 조정
        let brightness = star.brightness
        let starRadius = 0.15 + (brightness * 0.1) // 밝을수록 크게
        
        // 모든 별을 흰색 베이스로 설정, 밝기만으로 차이 표현
        let starColor = UIColor.white
        
        // 메인 별 노드 생성
        let node = SCNNode()
        node.name = star.id
        node.position = star.position
        
        // 1) 핵심 별 (가장 밝은 부분)
        let coreSphere = SCNSphere(radius: CGFloat(starRadius * 0.3))
        let coreMat = SCNMaterial()
        coreMat.diffuse.contents = UIColor.white
        coreMat.lightingModel = .constant
        coreMat.transparency = CGFloat(brightness * 0.8 + 0.2) // 밝을수록 더 불투명하게
        coreSphere.materials = [coreMat]
        
        let coreNode = SCNNode(geometry: coreSphere)
        coreNode.name = "\(star.id)_core"
        node.addChildNode(coreNode)
        
        // 2) 중간 레이어 (별의 본체)
        let middleSphere = SCNSphere(radius: CGFloat(starRadius * 0.6))
        let middleMat = SCNMaterial()
        middleMat.diffuse.contents = starColor
        middleMat.lightingModel = .constant
        middleMat.transparency = CGFloat(brightness * 0.6 + 0.2) // 밝을수록 더 불투명하게
        middleSphere.materials = [middleMat]
        
        let middleNode = SCNNode(geometry: middleSphere)
        middleNode.name = "\(star.id)_middle"
        node.addChildNode(middleNode)
        
        // 3) 외부 레이어 (빛나는 효과)
        let outerSphere = SCNSphere(radius: CGFloat(starRadius))
        let outerMat = SCNMaterial()
        outerMat.diffuse.contents = starColor
        outerMat.lightingModel = .constant
        outerMat.transparency = CGFloat(brightness * 0.5) // 밝을수록 더 불투명하게
        outerSphere.materials = [outerMat]
        
        let outerNode = SCNNode(geometry: outerSphere)
        outerNode.name = "\(star.id)_outer"
        node.addChildNode(outerNode)
        
        // 4) 빛나는 효과를 위한 추가 레이어들
        let glowScales: [Float] = [1.2, 1.5, 2.0]
        for (index, scale) in glowScales.enumerated() {
            let glowSphere = SCNSphere(radius: CGFloat(starRadius * scale))
            let glowMat = SCNMaterial()
            glowMat.diffuse.contents = starColor
            glowMat.lightingModel = .constant
            glowMat.transparency = CGFloat(brightness * (0.4 - Float(index) * 0.1)) // 밝을수록 더 불투명하게
            glowSphere.materials = [glowMat]
            
            let glowNode = SCNNode(geometry: glowSphere)
            glowNode.name = "\(star.id)_glow_\(index)"
            node.addChildNode(glowNode)
        }
        
        // 5) 간단한 광원 효과 
        let simpleLight = SCNLight()
        simpleLight.type = .omni
        simpleLight.intensity = CGFloat(brightness * 50.0)
        simpleLight.color = starColor
        simpleLight.attenuationStartDistance = 0.1
        simpleLight.attenuationEndDistance = 2.0
        
        let lightNode = SCNNode()
        lightNode.light = simpleLight
        lightNode.position = SCNVector3Zero
        node.addChildNode(lightNode)

        // 2) 탭 인식을 위한 투명 히트 구체 (hitSphere)
        let hitSphere = SCNSphere(radius: 0.5)
        let hitMat = SCNMaterial()
        hitMat.diffuse.contents = UIColor.clear
        hitMat.transparency = 0.0
        hitSphere.materials = [hitMat]

        let hitNode = SCNNode(geometry: hitSphere)
        hitNode.name = star.id
        hitNode.position = SCNVector3Zero
        node.addChildNode(hitNode)

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
                let hitResult = scnView.hitTest(gesture.location(in: scnView), options: nil).first,
                hitResult.node.geometry is SCNSphere,
                let tappedNodeName = hitResult.node.name,
                let root = scnView.window?.rootViewController
            else {
                return
            }

            // 탭 직전 stars 내부 ID 디버깅
            print("현재 stars 배열 ID들:", stars.map { $0.id })
            print("탭한 노드 이름:", tappedNodeName)

            // stars 배열에서 해당 ID를 가진 Star 찾기
            guard let star = stars.first(where: { $0.id == tappedNodeName }) else {
                return
            }

            // 중복 탭 방지
            self.isTransitioning = true

            // StarInfoView 풀스크린 모달로 표시
            let infoView = StarInfoView(star: star)
            let vc = UIHostingController(rootView: infoView)
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve

            DispatchQueue.main.async {
                root.present(vc, animated: true) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.isTransitioning = false
                    }
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
        -> Bool {
            return true
        }
    }
}
