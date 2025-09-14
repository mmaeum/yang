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

        // 루프 재생을 위한 알림 설정
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            if isPlaying {
                player.play()
            }
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {}
}

struct StarInfoView: View {
    let star: Star
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var isTransitioning = false
    @State private var isSharePresented = false
    @State private var videoURL: URL?
    @State private var isPlaying = true

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 비디오 플레이어를 배경으로
                if isLoading {
                    Color.black
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                } else if let player = player {
                    FullScreenVideoPlayer(player: player, isPlaying: $isPlaying)
                        .ignoresSafeArea()
                        .onTapGesture {
                            togglePlayback()
                        }
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
                        Text(star.createdAt, format: .dateTime.year().month().day())
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
            loadVideo()
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
        .sheet(isPresented: $isSharePresented) {
            if let url = videoURL {
                ActivityViewController(activityItems: [url])
            }
        }
    }
    
    private func loadVideo() {
        star.getVideoURL { url in
            if let url = url {
                self.videoURL = url
                let newPlayer = AVPlayer(url: url)
                self.player = newPlayer

                // 루프 재생을 위한 알림 설정
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: newPlayer.currentItem,
                    queue: .main
                ) { _ in
                    newPlayer.seek(to: .zero)
                    if isPlaying {
                        newPlayer.play()
                    }
                }

                newPlayer.play() // 자동 재생 시작
            }
            isLoading = false
        }
    }

    private func togglePlayback() {
        guard let player = player else { return }

        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
}
