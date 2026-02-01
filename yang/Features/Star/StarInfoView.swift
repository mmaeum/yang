// 3) StarInfoView.swift
import SwiftUI
import AVKit
import Photos
import UIKit

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct FullScreenVideoPlayer: UIViewControllerRepresentable {
    let player: AVPlayer
    @Binding var isPlaying: Bool

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = false  // 기본 컨트롤 숨기기
        controller.videoGravity = .resizeAspectFill

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        uiViewController.player = player
    }

    static func dismantleUIViewController(_ uiViewController: AVPlayerViewController, coordinator: ()) {
        uiViewController.player = nil
    }
}

struct StarInfoView: View {
    let stars: [Star]
    let initialStarId: String
    @Environment(\.presentationMode) var presentationMode
    @State private var currentIndex: Int = 0
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var isTransitioning = false
    @State private var isSharePresented = false
    @State private var videoURL: URL?
    @State private var isPlaying = true
    @State private var downloadProgress: Double = 0
    @State private var errorMessage: String?
    @State private var playbackObserver: NSObjectProtocol?
    @State private var dragOffset: CGFloat = 0
    @State private var videoRequestID: PHImageRequestID?

    private var sortedStars: [Star] {
        stars.sorted { $0.createdAt > $1.createdAt }
    }

    private var currentStar: Star {
        sortedStars[currentIndex]
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 비디오 플레이어를 배경으로
                if isLoading {
                    Color.black
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        ProgressView(value: max(downloadProgress, 0.02), total: 1.0)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.5)
                        VStack(spacing: 6) {
                            Text("iCloud에서 비디오를 불러오는 중입니다…")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                } else if let player = player {
                    FullScreenVideoPlayer(player: player, isPlaying: $isPlaying)
                        .ignoresSafeArea()
                        .onTapGesture {
                            togglePlayback()
                        }
                        .offset(y: dragOffset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    dragOffset = value.translation.height
                                }
                                .onEnded { value in
                                    handleSwipe(translation: value.translation.height)
                                }
                        )
                } else if let errorMessage = errorMessage {
                    Color.black
                        .ignoresSafeArea()
                    VStack(spacing: 16) {
                        Image(systemName: "icloud.slash")
                            .font(.system(size: 32, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                        Text(errorMessage)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 32)
                        Button(action: {
                            loadVideo()
                        }) {
                            Text("다시 시도")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.white)
                                .cornerRadius(30)
                                .padding(.horizontal, 60)
                        }
                        .padding(.top, 10)
                    }
                } else {
                    Color.black
                        .ignoresSafeArea()
                }
                
                // UI 요소들을 오버레이
                VStack(spacing: 0) {
                    HStack {
                        // 닫기 버튼 (왼쪽 상단)
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .opacity(0.8)

                        Spacer()
                        Text(currentStar.createdAt, format: .dateTime.year().month().day())
                            .font(Font.custom("Press Start 2P", size: 12))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 0.00, green: 0.00, blue: 0.00, opacity: 0.16), radius: 20, x: 0, y: 0)
                            .offset(x: 0, y: 10)
                        Spacer()
                    }
                    .padding(.top, 10)
                    .padding(.horizontal, 20)

                    Spacer()

                    // 하단 컨트롤
                    VStack(spacing: 0) {
                        // Share 버튼
                        HStack {
                            Spacer()
                            Button(action: {
                                isSharePresented = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)

                                    Text("Share")
                                        .font(.system(size: 17, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 14)
                                .padding(.horizontal, 40)
                                .frame(width: 191)
                                .background(Color.black.opacity(0.6))
                                .cornerRadius(100)
                            }
                            .opacity(0.8)
                            Spacer()
                        }
                        .frame(height: 96)

                    }
                }
            }
        }
        .onAppear {
            if let index = sortedStars.firstIndex(where: { $0.id == initialStarId }) {
                currentIndex = index
            }
            loadVideo()
        }
        .onDisappear {
            // 진행 중인 요청 취소
            if let requestID = videoRequestID {
                PHImageManager.default().cancelImageRequest(requestID)
                videoRequestID = nil
            }
            cleanupPlayer()
        }
        .onChange(of: currentIndex) { _ in
            loadVideo()
        }
        .sheet(isPresented: $isSharePresented) {
            if let url = videoURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    /// `loadVideo`: iCloud 다운로드 진행률을 초기화하고 비디오 URL 요청을 시작한다.
    private func loadVideo() {
        // 이전 요청 취소
        if let requestID = videoRequestID {
            PHImageManager.default().cancelImageRequest(requestID)
            videoRequestID = nil
        }

        cleanupPlayer()
        isPlaying = true
        errorMessage = nil
        downloadProgress = 0
        isLoading = true
        videoURL = nil

        let newRequestID = currentStar.getVideoURL(progress: { [self] progress in
            DispatchQueue.main.async {
                self.downloadProgress = min(max(progress, 0), 1)
            }
        }) { [self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let url):
                    self.videoURL = url
                    self.setupPlayer(with: url)
                case .failure(let error):
                    self.handleLoadFailure(error)
                }
            }
        }

        videoRequestID = newRequestID
    }
    
    /// `setupPlayer`: 가져온 URL로 AVPlayer를 구성하고 루프 재생 옵저버를 등록한다.
    private func setupPlayer(with url: URL) {
        let newPlayer = AVPlayer(url: url)
        player = newPlayer
        
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        playbackObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: newPlayer.currentItem,
            queue: .main
        ) { _ in
            newPlayer.seek(to: .zero)
            if isPlaying {
                newPlayer.play()
            }
        }
        
        if isPlaying {
            newPlayer.play()
        }
        isLoading = false
    }
    
    /// `handleLoadFailure`: 비디오 로딩 실패 시 사용자 메시지를 구성하고 상태를 리셋한다.
    private func handleLoadFailure(_ error: Error) {
        cleanupPlayer()
        isLoading = false
        errorMessage = "비디오를 불러올 수 없습니다.\n\(error.localizedDescription)"
    }
    
    /// `cleanupPlayer`: 플레이어와 Notification 옵저버를 안전하게 해제한다.
    private func cleanupPlayer() {
        // Notification observer 제거
        if let observer = playbackObserver {
            NotificationCenter.default.removeObserver(observer)
            playbackObserver = nil
        }

        // Player 정리
        if let currentPlayer = player {
            currentPlayer.pause()
            currentPlayer.replaceCurrentItem(with: nil)
            player = nil
        }

        // 비디오 URL 정리
        videoURL = nil
    }

    /// `togglePlayback`: 탭 입력에 따라 재생/일시정지를 전환한다.
    private func togglePlayback() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }

    /// `handleSwipe`: 스와이프 제스처를 처리하여 다음/이전 비디오로 이동한다.
    private func handleSwipe(translation: CGFloat) {
        let threshold: CGFloat = 50

        if translation < -threshold {
            // 위로 스와이프: 더 오래된 동영상 (인덱스 증가)
            if currentIndex < sortedStars.count - 1 {
                currentIndex += 1
            }
        } else if translation > threshold {
            // 아래로 스와이프: 더 최근 동영상 (인덱스 감소)
            if currentIndex > 0 {
                currentIndex -= 1
            }
        }

        withAnimation(.easeInOut(duration: 0.3)) {
            dragOffset = 0
        }
    }
}
