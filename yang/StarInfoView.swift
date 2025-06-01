import SwiftUI
import AVKit
import Photos

struct StarInfoView: View {
    let star: Star
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isLoading = true
    
    var body: some View {
        HStack(spacing: 0) {
            // 왼쪽 패널
            VStack(alignment: .leading, spacing: 20) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                    Text("뒤로가기")
                }
                .padding()
                
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
                
                Spacer()
            }
            .frame(width: 200)
            .background(Color.black.opacity(0.8))
            
            // 오른쪽 패널 (비디오)
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else if let player = player {
                VideoPlayer(player: player)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundColor(.white)
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        star.getVideoURL { url in
            if let url = url {
                player = AVPlayer(url: url)
            }
            isLoading = false
        }
    }
}
