import SwiftUI
import SceneKit
import Photos

struct ContentView: View {
    @State private var stars: [Star] = []
    @State private var isLoading = true
    @State private var timeLeft: String = ""
    
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
        GeometryReader { geometry in
            ZStack {
                // Group 제거, 내부 View들을 직접 나열
                Ellipse()
                    .foregroundColor(.clear)
                    .frame(width: geometry.size.width * 1.2, height: geometry.size.width * 1.2)
                    .offset(x: 0, y: 0.50)
                StarFieldView(
                    scene: scene,
                    stars: $stars,
                    isLoading: isLoading,
                    width: geometry.size.width,
                    height: geometry.size.height
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: UIApplication.shared.connectedScenes
                            .compactMap { $0 as? UIWindowScene }
                            .first?.statusBarManager?.statusBarFrame.height ?? 44)
                    HStack {
                        Spacer()
                        HamburgerMenuButton {
                            // 메뉴 액션 추가 예정
                        }
                        .padding(.trailing, 8)
                    }
                    .padding(.bottom, 32)
                    HeaderTextView()
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                VStack {
                    Spacer()
                    CountdownTimerView(timeLeft: timeLeft)
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
                .padding(.bottom, geometry.size.height * 0.3)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(.black)
        }
        .ignoresSafeArea(.all)
        .onAppear {
            loadVideos()
            updateTimeLeft()
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTimeLeft()
            }
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
    
    private func updateTimeLeft() {
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now)!)
        let diff = Int(tomorrow.timeIntervalSince(now))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        timeLeft = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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

