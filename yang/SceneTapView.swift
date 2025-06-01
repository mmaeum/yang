import SwiftUI
import SceneKit
import Photos

struct SceneTapView: UIViewRepresentable {
    let scene: SCNScene
    @Binding var stars: [Star]
    @State private var isLoading = true

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

        // yang 앨범에서 비디오 불러오기
        loadVideosFromYangAlbum { videos in
            stars = videos
            isLoading = false
        }

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
        let sphere = SCNSphere(radius: 0.05)
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

    private func loadVideosFromYangAlbum(completion: @escaping ([Star]) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            // yang 앨범 찾기
            let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)
            var yangAlbum: PHAssetCollection?
            
            collections.enumerateObjects { collection, _, _ in
                if collection.localizedTitle == "yang" {
                    yangAlbum = collection
                }
            }
            
            guard let album = yangAlbum else {
                completion([])
                return
            }
            
            // 비디오 에셋 가져오기
            let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
            var stars: [Star] = []
            
            assets.enumerateObjects { asset, index, _ in
                if asset.mediaType == .video {
                    let position = SCNVector3(
                        Float.random(in: -20...20),
                        Float.random(in: -20...20),
                        Float.random(in: -20...20)
                    )
                    let star = Star(asset: asset, position: position)
                    stars.append(star)
                }
            }
            
            completion(stars)
        }
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
