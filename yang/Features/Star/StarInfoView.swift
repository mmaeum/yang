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
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        controller.showsPlaybackControls = true
        controller.videoGravity = .resizeAspectFill
        
        // 비디오 자동 재생 설정
        player.play()
        
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
                    FullScreenVideoPlayer(player: player)
                        .ignoresSafeArea()
                }
                
                // UI 요소들을 오버레이
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Text(star.createdAt, format: .dateTime.year().month().day())
                            .font(Font.custom("Press Start 2P", size: 12))
                            .foregroundColor(.white)
                            .shadow(color: Color(red: 0.00, green: 0.00, blue: 0.00, opacity: 0.16), radius: 20, x: 0, y: 0)
                            .offset(x: 0, y: 10)
                        Spacer()
                    }
                    .padding(.top, 10)
                    
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
                newPlayer.play() // 여기서도 재생 시작
            }
            isLoading = false
        }
    }
}
