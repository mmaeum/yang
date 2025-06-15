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
                    // 상단 컨트롤
                    HStack {
                        // X 버튼
                        Button(action: {
                            player?.pause()
                            player = nil
                            if let root = UIApplication.shared.windows.first?.rootViewController {
                                root.dismiss(animated: false, completion: nil)
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.7))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "xmark")
                                    .foregroundColor(.white)
                                    .font(.system(size: 20, weight: .medium))
                            }
                        }
                        .padding(.leading, 16)
                        
                        Spacer()
                        
                        // 날짜 표시
                        Text(star.createdAt, format: .dateTime.year().month().day())
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 12)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(100)
                        
                        Spacer()
                        
                        // 오른쪽 여백을 위한 투명 뷰
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 44, height: 44)
                            .padding(.trailing, 16)
                    }
                    .padding(.top, 21)
                    
                    Spacer()
                    
                    // 하단 컨트롤
                    VStack(spacing: 0) {
                        // Share 버튼
                        HStack {
                            Spacer()
                            Button(action: {
                                isSharePresented = true
                            }) {
                                Text("Share")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(.vertical, 14)
                                    .padding(.horizontal, 40)
                                    .frame(width: 191)
                                    .cornerRadius(100)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 100)
                                            .inset(by: 0.50)
                                            .stroke(.white, lineWidth: 0.50)
                                    )
                            }
                            Spacer()
                        }
                        .frame(height: 96)
                        
                        // 하단 인디케이터
                        HStack {
                            Spacer()
                            Rectangle()
                                .foregroundColor(.white)
                                .frame(width: 144, height: 5)
                                .cornerRadius(100)
                            Spacer()
                        }
                        .frame(height: 34)
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
