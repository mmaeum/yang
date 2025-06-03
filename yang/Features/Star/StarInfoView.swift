// 3) StarInfoView.swift
import SwiftUI
import AVKit

struct StarInfoView: View {
    let star: Star
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isLoading = true
    @State private var isTransitioning = false

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    guard !isTransitioning else { return }
                    isTransitioning = true
                    player?.pause()
                    player = nil
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("뒤로가기")
                    }
                }
                .padding()
                .disabled(isTransitioning)

                Spacer()

                Text("Created: \(star.createdAt.formatted())")
                    .font(.headline)
                    .padding(.horizontal)

                Button(action: {
                    let videoRecordingView = VideoRecordingView()
                    let hostingController = UIHostingController(rootView: videoRecordingView)
                    UIApplication.shared.windows.first?.rootViewController?.present(hostingController, animated: true)
                }) {
                    Text("비디오 촬영")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(isTransitioning)

                Spacer()
            }
            .frame(width: 200)
            .background(Color.black.opacity(0.8))

            ZStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else if let player = player {
                    VideoPlayer(player: player)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if isTransitioning {
                    Color.black.opacity(0.5)
                        .edgesIgnoringSafeArea(.all)
                }
            }
        }
        .foregroundColor(.white)
        .onAppear {
            star.getVideoURL { url in
                if let url = url {
                    player = AVPlayer(url: url)
                }
                isLoading = false
            }
        }
        .onDisappear {
            player?.pause()
            player = nil
        }
    }
}
