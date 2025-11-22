import SwiftUI
import SceneKit
import Photos

class PhotoLibraryObserver: NSObject, PHPhotoLibraryChangeObserver {
    var onChange: (() -> Void)?

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        print("📸 PhotoLibraryObserver: Photo library changed")
        DispatchQueue.main.async {
            self.onChange?()
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var stars: [Star] = []
    @State private var isLoading = true
    @State private var timeLeft: String = ""
    @State private var showCredits = false
    @State private var countdownStartOfDay = Calendar.current.startOfDay(for: Date())
    @State private var countdownTimer: Timer?
    @State private var forceRefresh = false
    @State private var photoObserver = PhotoLibraryObserver()
    
    private let scene: SCNScene = {
        let scene = SCNScene()
        scene.background.contents = UIColor.clear  // 투명한 배경으로 변경

        let camNode = SCNNode()
        camNode.camera = SCNCamera()
        camNode.position = SCNVector3(0, 0, 30)
        scene.rootNode.addChildNode(camNode)

        return scene
    }()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 동영상 StarField 영역
                StarFieldView(
                    scene: scene,
                    stars: $stars,
                    isLoading: isLoading,
                    width: geometry.size.width,
                    height: geometry.size.height,
                    forceRefresh: forceRefresh
                )
                .frame(width: geometry.size.width, height: geometry.size.height)
                // 햄버거 버튼 + 타이틀 영역
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        HamburgerMenuButton {
                            showCredits = true
                        }
                        .padding(.trailing, 20)
                        .zIndex(1000)
                    }
                    .padding(.top, geometry.safeAreaInsets.top + 60)
                    .padding(.bottom, geometry.size.height * 0.05)
                    HeaderTextView()
                    Spacer()
                }
                .frame(width: geometry.size.width, alignment: .top)
                // 카운트 다운 영역
                VStack {
                    Spacer()
                    CountdownTimerView(timeLeft: timeLeft)
                }
                .frame(width: geometry.size.width, alignment: .bottom)
                .padding(.bottom, geometry.size.height * 0.2)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .ignoresSafeArea(.all)
        .overlay(
            CreditsView(onDismiss: {
                showCredits = false
            })
                .opacity(showCredits ? 1 : 0)
                .animation(.easeInOut(duration: 0.3), value: showCredits)
                .allowsHitTesting(showCredits)
        )
        .onAppear {
            loadVideos()
            updateTimeLeft()
            countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                updateTimeLeft()
            }

            // PHPhotoLibrary 변경 감지 observer 등록
            photoObserver.onChange = {
                print("🔄 ContentView: Photo library changed, reloading videos")
                loadVideos()
                forceRefresh.toggle()
            }
            PHPhotoLibrary.shared().register(photoObserver)
        }
        .onDisappear {
            countdownTimer?.invalidate()
            countdownTimer = nil

            // Observer 해제
            PHPhotoLibrary.shared().unregisterChangeObserver(photoObserver)
        }
        .onChange(of: appState.hasTodayVideo) { hasVideo in
            print("📺 ContentView: hasTodayVideo changed to \(hasVideo)")
            // observer가 자동으로 사진 라이브러리 변경사항을 감지하므로 수동 로드 불필요
        }
    }
    
    private func loadVideos() {
        print("🔄 ContentView: loadVideos() called")
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
        print("📚 ContentView: loadVideosFromAlbum() called")
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
            print("⚠️ ContentView: yang album not found")
            DispatchQueue.main.async {
                isLoading = false
            }
            return
        }

        // 비디오 에셋 가져오기
        let assets = PHAsset.fetchAssets(in: album, options: fetchOptions)
        print("📹 ContentView: Found \(assets.count) assets in yang album")
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

        print("⭐ ContentView: Created \(newStars.count) stars")
        DispatchQueue.main.async {
            self.stars = newStars
            self.isLoading = false
            print("✅ ContentView: Stars updated in main thread, total stars: \(self.stars.count)")
        }
    }
    
    private func updateTimeLeft() {
        let now = Date()
        let calendar = Calendar.current
        let endOfCurrentDay = calendar.date(byAdding: .day, value: 1, to: countdownStartOfDay)!

        if now >= endOfCurrentDay {
            countdownStartOfDay = calendar.startOfDay(for: now)
            handleCountdownFinished()
        }

        let endOfDay = calendar.date(byAdding: .day, value: 1, to: countdownStartOfDay)!
        let diff = max(0, Int(endOfDay.timeIntervalSince(now)))
        let hours = diff / 3600
        let minutes = (diff % 3600) / 60
        let seconds = diff % 60
        timeLeft = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    private func handleCountdownFinished() {
        DispatchQueue.main.async {
            appState.hasTodayVideo = false
        }

        PhotoLibraryChecker.checkForTodayVideosInYangFolder { hasVideos in
            DispatchQueue.main.async {
                appState.hasTodayVideo = hasVideos
            }
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
    static var previews: some View {
        ContentView()
            .environmentObject(AppState())
    }
}

