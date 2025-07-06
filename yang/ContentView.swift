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
            Group {
                Ellipse()
                    .foregroundColor(.clear)
                    .frame(width: 967, height: 967)
                    .offset(x: 0, y: 0.50)
                ZStack {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                    } else {
                        StarListView(scene: scene, stars: $stars)
                            .frame(width: 393, height: 393)
                            .cornerRadius(100)
                    }
                }
                .frame(width: 393, height: 393)
                .cornerRadius(100)
                .offset(x: 0, y: 16.50)
                VStack(alignment: .leading, spacing: nil) {
                    HStack(spacing: 134) {
                        HStack(spacing: 10) {
                            Text("9:41")
                                .font(Font.custom("SF Pro", size: 17).weight(.regular))
                                .lineSpacing(22)
                                .foregroundColor(.white)
                        }
                        .padding(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 6))
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 124, height: 10)
                        HStack(spacing: 7) {
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 25, height: 13)
                                .cornerRadius(4.30)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4.30)
                                        .inset(by: 0.50)
                                        .stroke(.white, lineWidth: 0.50)
                                )
                            Rectangle()
                                .foregroundColor(.clear)
                                .frame(width: 21, height: 9)
                                .background(.white)
                                .cornerRadius(2.50)
                        }
                        .padding(EdgeInsets(top: 0, leading: 6, bottom: 0, trailing: 16))
                    }
                }
                .padding(EdgeInsets(top: 21, leading: 0, bottom: 0, trailing: 0))
                .frame(width: 393, height: 50)
                .offset(x: 0, y: -401)
                ZStack {
                    Text("YANG")
                        .font(Font.custom("Press Start 2P", size: 12))
                        .foregroundColor(.white)
                        .shadow(color: Color(red: 0.00, green: 0.00, blue: 0.00, opacity: 0.16), radius: 20, x: 0, y: 0)
                        .offset(x: 0, y: 0)
                    HStack(spacing: 10) {
                        ZStack {

                        }
                        .frame(width: 12, height: 12)
                    }
                    .frame(width: 52, height: 52)
                    .background(Color(red: 0, green: 0, blue: 0).opacity(0.40))
                    .cornerRadius(100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 100)
                            .inset(by: 0.25)
                            .stroke(
                                Color(red: 1, green: 1, blue: 1).opacity(0.30), lineWidth: 0.25
                            )
                    )
                    .offset(x: 142.50, y: 0)
                }
                .frame(width: 393, height: 84)
                .offset(x: 0, y: -334)
                VStack(alignment: .leading, spacing: nil) {
                    ZStack {
                        Rectangle()
                            .foregroundColor(.clear)
                            .frame(width: 144, height: 5)
                            .background(.white)
                            .cornerRadius(100)
                            .offset(x: 144.50, y: 11.50)
                    }
                    .frame(height: 34)
                }
                .frame(width: 393)
                .offset(x: 0, y: 409)
                Text("Memories are not just about the past.\nThey shape who we are")
                    .font(Font.custom("Share Tech Mono", size: 14))
                    .foregroundColor(.white)
                    .offset(x: 0, y: -216)
                Text("left for the next memory")
                    .font(Font.custom("Share Tech Mono", size: 12))
                    .foregroundColor(.white)
                    .offset(x: 0, y: 307)
                Text("Memory Bank")
                    .font(Font.custom("Share Tech Mono", size: 28))
                    .lineSpacing(28)
                    .foregroundColor(.white)
                    .offset(x: 0, y: -258)
                Text("23:08:30")
                    .font(Font.custom("Press Start 2P", size: 16))
                    .foregroundColor(Color(red: 1, green: 0.51, blue: 0.03))
                    .offset(x: 0, y: 285)
            }
        }
        .frame(width: 393, height: 852)
        .background(.black)
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
                // 비디오의 고유 식별자를 시드값으로 사용
                let seed = UInt64(abs(asset.localIdentifier.hash))
                var random = SeededRandomNumberGenerator(seed: seed)
                
                // 최신 비디오일수록 중앙에 가깝게 위치
                let distance = Float(index) * 2.0
                let angle = Float.random(in: 0...(2 * .pi), using: &random)
                
                let position = SCNVector3(
                    distance * cos(angle),
                    distance * sin(angle),
                    Float.random(in: -5...5, using: &random)
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

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var generator: UInt64
    
    init(seed: UInt64) {
        generator = seed
    }
    
    mutating func next() -> UInt64 {
        generator = generator &* 6364136223846793005 &+ 1442695040888963407
        return generator
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View { ContentView() }
}

