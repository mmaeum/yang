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
            // yang 앨범에서 비디오 불러오기
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
                    isLoading = false
                    return
                }
                
                // 비디오 에셋 가져오기
                let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
                var newStars: [Star] = []
                
                assets.enumerateObjects { asset, index, _ in
                    if asset.mediaType == .video {
                        let position = SCNVector3(
                            Float.random(in: -20...20),
                            Float.random(in: -20...20),
                            Float.random(in: -20...20)
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
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}

