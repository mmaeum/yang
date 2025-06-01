import SwiftUI
import AVKit
import Photos

struct StarInfoView: View {
    let star: Star
    @Environment(\.presentationMode) var presentationMode
    @State private var player: AVPlayer?
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                        Text("뒤로가기")
                    }
                    .padding()
                    Spacer()
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.5)
                } else if let player = player {
                    VideoPlayer(player: player)
                        .frame(height: 300)
                        .cornerRadius(12)
                        .padding()
                }
                
                Text("Created: \(star.createdAt.formatted())")
                    .font(.headline)
                
                NavigationLink(destination: VideoRecordingView()) {
                    Text("비디오 촬영")
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .background(Color.black.opacity(0.8))
            .foregroundColor(.white)
            .onAppear {
                loadVideo()
            }
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
