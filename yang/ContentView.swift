import SwiftUI
import SceneKit
import Photos

struct ContentView: View {
    @State private var stars: [Star] = []
    @State private var isLoading = true
    
    private let scene: SCNScene = {
        let scene = SCNScene()
        scene.background.contents = UIColor.black
        
        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.position = SCNVector3(0, 0, 30)
        scene.rootNode.addChildNode(camNode)
        
        return scene
    }()
    
    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else {
                SceneTapView(scene: scene, stars: $stars)
                    .edgesIgnoringSafeArea(.all)
            }
        }
        .onAppear {
            loadVideos()
        }
    }
    
    private func loadVideos() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        switch status {
        case .authorized, .limited:
            loadVideosFromAlbum()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    if newStatus == .authorized || newStatus == .limited {
                        loadVideosFromAlbum()
                    } else {
                        isLoading = false
                    }
                }
            }
        default:
            isLoading = false
        }
    }
    
    private func loadVideosFromAlbum() {
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
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }
        
        // 비디오 에셋 가져오기
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        var newStars: [Star] = []
        
        assets.enumerateObjects { asset, index, stop in
            if asset.mediaType == .video {
                // 최신 비디오일수록 중앙에 가깝게 위치
                let distance = Float(index) * 2.0  // 인덱스가 클수록(오래된 비디오일수록) 더 멀리
                let angle = Float.random(in: 0...(2 * .pi))  // 랜덤한 각도
                
                let position = SCNVector3(
                    distance * cos(angle),  // x 좌표
                    distance * sin(angle),  // y 좌표
                    Float.random(in: -5...5)  // z 좌표는 약간의 랜덤성 부여
                )
                
                let star = Star(asset: asset, position: position)
                newStars.append(star)
            }
        }
        
        DispatchQueue.main.async {
            stars = newStars
            isLoading = false
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}

