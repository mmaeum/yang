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
    
    private func makeRadialGradient(diameter: CGFloat) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let ctx = UIGraphicsGetCurrentContext() else {
            fatalError("그래픽 컨텍스트 생성 실패")
        }

        ctx.clear(CGRect(origin: .zero, size: size))
        
        let colors = [UIColor.white.cgColor, UIColor.clear.cgColor] as CFArray
        let locations: [CGFloat] = [0.0, 1.0]
        let space = CGColorSpaceCreateDeviceRGB()
        guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: locations) else {
            fatalError("그라데이션 생성 실패")
        }

        let center = CGPoint(x: size.width/2, y: size.height/2)
        let radius = diameter/2

        ctx.drawRadialGradient(
            grad,
            startCenter: center, startRadius: 0,
            endCenter: center,   endRadius: radius,
            options: .drawsBeforeStartLocation
        )

        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }

    private func createStarNode(for star: Star) -> SCNNode {
        let brightness = CGFloat(star.brightness)
        
        let starRadius = 0.1 + brightness * 0.2
        let scaleFactor: CGFloat = 3.0
        let scaledRadius = starRadius * scaleFactor

        let node = SCNNode()
        node.name = star.id
        node.position = star.position

        let planeSize = scaledRadius * 2.0
        let gradImg = makeRadialGradient(diameter: planeSize * 50.0)

        let plane = SCNPlane(width: planeSize, height: planeSize)
        let mat = SCNMaterial()
        mat.diffuse.contents      = gradImg
        mat.lightingModel         = .constant
        mat.blendMode             = .add
        mat.isDoubleSided         = true
        mat.writesToDepthBuffer   = false
        plane.firstMaterial       = mat

        let planeNode = SCNNode(geometry: plane)
        let bb = SCNBillboardConstraint()
        bb.freeAxes = .all
        planeNode.constraints = [bb]
        node.addChildNode(planeNode)

        let light = SCNLight()
        light.type                  = .omni
        light.intensity             = brightness * 50.0
        light.attenuationStartDistance = 0.1
        light.attenuationEndDistance   = 2.0
        let lightNode = SCNNode()
        lightNode.light = light
        node.addChildNode(lightNode)

        let hitRadius = max(0.5, scaledRadius * 1.5)
        let hitSphere = SCNSphere(radius: hitRadius)
        let hitMat = SCNMaterial()
        hitMat.diffuse.contents      = UIColor.clear
        hitMat.transparency          = 0.0
        hitMat.lightingModel         = .constant
        hitSphere.materials          = [hitMat]
        let hitNode = SCNNode(geometry: hitSphere)
        hitNode.name = star.id
        hitNode.renderingOrder = 200
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
