import SwiftUI
import SceneKit

struct SceneTapView: UIViewRepresentable {
    let scene: SCNScene

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

    func updateUIView(_ uiView: SCNView, context: Context) { }

    func makeCoordinator() -> Coordinator { Coordinator() }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard
                let scnView = gesture.view as? SCNView,
                let hit = scnView.hitTest(gesture.location(in: scnView), options: nil).first,
                hit.node.geometry is SCNSphere,
                let name = hit.node.name,
                let idx = Int(name),
                let root = scnView.window?.rootViewController
            else { return }

            let infoView = StarInfoView(index: idx)
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
