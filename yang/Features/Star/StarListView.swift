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
        scnView.autoenablesDefaultLighting = false  // 기본 조명 비활성화
        scnView.allowsCameraControl = true
        
        // 안정적인 환경 조명 설정
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 0.3  // 강도 증가
        ambientLight.color = UIColor.white
        
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)
        
        // 전방향 조명 추가로 일관된 밝기 유지
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = 0.5
        directionalLight.color = UIColor.white
        directionalLight.castsShadow = false
        
        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = SCNVector3(0, 10, 10)
        directionalNode.look(at: SCNVector3(0, 0, 0))
        scene.rootNode.addChildNode(directionalNode)

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
        // 밝기에 따라 별의 크기와 색상 조정 - 더 드라마틱한 차이
        let brightness = star.brightness
        let starRadius = 0.1 + (brightness * 0.2) // 밝을수록 더 크게 (0.1 ~ 0.3)
        
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
        coreMat.transparency = CGFloat(brightness * 0.9 + 0.1) // 더 극적인 투명도 차이
        coreMat.isDoubleSided = true
        coreMat.writesToDepthBuffer = false // 깊이 버퍼 쓰기 비활성화로 안정성 향상
        coreSphere.materials = [coreMat]
        
        let coreNode = SCNNode(geometry: coreSphere)
        coreNode.name = "\(star.id)_core"
        coreNode.renderingOrder = 100 // 렌더링 순서 설정
        node.addChildNode(coreNode)
        
        // 2) 중간 레이어 (별의 본체)
        let middleSphere = SCNSphere(radius: CGFloat(starRadius * 0.6))
        let middleMat = SCNMaterial()
        middleMat.diffuse.contents = starColor
        middleMat.lightingModel = .constant
        middleMat.transparency = CGFloat(brightness * 0.8 + 0.1) // 더 극적인 투명도 차이
        middleMat.isDoubleSided = true
        middleMat.writesToDepthBuffer = false
        middleSphere.materials = [middleMat]
        
        let middleNode = SCNNode(geometry: middleSphere)
        middleNode.name = "\(star.id)_middle"
        middleNode.renderingOrder = 50
        node.addChildNode(middleNode)
        
        // 3) 외부 레이어 (빛나는 효과)
        let outerSphere = SCNSphere(radius: CGFloat(starRadius))
        let outerMat = SCNMaterial()
        outerMat.diffuse.contents = starColor
        outerMat.lightingModel = .constant
        outerMat.transparency = CGFloat(brightness * 0.7) // 더 극적인 투명도 차이
        outerMat.isDoubleSided = true
        outerMat.writesToDepthBuffer = false
        outerSphere.materials = [outerMat]
        
        let outerNode = SCNNode(geometry: outerSphere)
        outerNode.name = "\(star.id)_outer"
        outerNode.renderingOrder = 25
        node.addChildNode(outerNode)
        
        // 4) 빛나는 효과를 위한 추가 레이어들
        let glowScales: [Float] = [1.2, 1.5, 2.0]
        for (index, scale) in glowScales.enumerated() {
            let glowSphere = SCNSphere(radius: CGFloat(starRadius * scale))
            let glowMat = SCNMaterial()
            glowMat.diffuse.contents = starColor
            glowMat.lightingModel = .constant
            glowMat.transparency = CGFloat(brightness * (0.6 - Float(index) * 0.15)) // 더 극적인 glow 차이
            glowMat.isDoubleSided = true
            glowMat.writesToDepthBuffer = false
            glowSphere.materials = [glowMat]
            
            let glowNode = SCNNode(geometry: glowSphere)
            glowNode.name = "\(star.id)_glow_\(index)"
            glowNode.renderingOrder = 10 - index // glow는 뒤에서부터 렌더링
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

        // 2) 탭 인식을 위한 투명 히트 구체 (hitSphere) - 별 크기에 맞게 조정
        let hitRadius = max(0.5, starRadius * 1.5) // 별보다 충분히 크게, 최소 0.5
        let hitSphere = SCNSphere(radius: CGFloat(hitRadius))
        let hitMat = SCNMaterial()
        hitMat.diffuse.contents = UIColor.clear
        hitMat.transparency = 0.0
        hitMat.lightingModel = .constant
        hitSphere.materials = [hitMat]

        let hitNode = SCNNode(geometry: hitSphere)
        hitNode.name = star.id
        hitNode.position = SCNVector3Zero
        hitNode.renderingOrder = 200 // 가장 앞에 렌더링하여 탭 우선순위 높임
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
                let root = scnView.window?.rootViewController
            else {
                return
            }
            
            // hitTest 옵션 개선
            let hitTestOptions: [SCNHitTestOption: Any] = [
                .searchMode: SCNHitTestSearchMode.closest.rawValue,
                .ignoreHiddenNodes: true
            ]
            
            guard let hitResult = scnView.hitTest(gesture.location(in: scnView), options: hitTestOptions).first,
                  let tappedNodeName = hitResult.node.name
            else {
                print("탭 감지 실패")
                return
            }

            // 탭한 노드가 실제 별 노드인지 확인 (glow 노드도 처리)
            let actualStarId: String
            if tappedNodeName.contains("_glow_") || tappedNodeName.contains("_core") || tappedNodeName.contains("_middle") || tappedNodeName.contains("_outer") {
                // glow, core, middle, outer 노드인 경우 별 ID 추출
                let components = tappedNodeName.components(separatedBy: "_")
                actualStarId = components[0]
                print("Glow/Core/Middle/Outer 노드 탭됨: \(tappedNodeName) -> 별 ID: \(actualStarId)")
            } else {
                // 직접 별 노드인 경우
                actualStarId = tappedNodeName
            }
            
            // 탭 직전 stars 내부 ID 디버깅
            print("현재 stars 배열 ID들:", stars.map { $0.id })
            print("탭한 노드 이름: \(tappedNodeName) -> 실제 별 ID: \(actualStarId)")

            // stars 배열에서 해당 ID를 가진 Star 찾기
            guard let star = stars.first(where: { $0.id == actualStarId }) else {
                print("별을 찾을 수 없음: \(actualStarId)")
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
