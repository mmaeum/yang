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
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true

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
        // 1) 실제로 보이는 흰 구체
        let sphere = SCNSphere(radius: 0.2)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.white
        mat.emission.contents = UIColor.white
        mat.lightingModel = .constant
        sphere.materials = [mat]

        let node = SCNNode(geometry: sphere)
        // 부모 노드에도 star.id(= asset.localIdentifier) 그대로 이름 설정
        node.name = star.id
        node.position = star.position

        // 2) 탭 인식을 위한 투명 히트 구체 (hitSphere)
        let hitSphere = SCNSphere(radius: 0.5)
        let hitMat = SCNMaterial()
        hitMat.diffuse.contents = UIColor.clear
        hitMat.transparency = 0.0
        hitSphere.materials = [hitMat]

        let hitNode = SCNNode(geometry: hitSphere)
        // 자식 히트 노드에도 같은 이름 star.id
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
