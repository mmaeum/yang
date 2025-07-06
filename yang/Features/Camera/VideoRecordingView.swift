import SwiftUI
import AVFoundation
import UIKit
import Photos

struct VideoRecordingView: View {
    @StateObject private var viewModel = VideoRecordingViewModel()
    @Environment(\.presentationMode) var presentationMode
    let onVideoSaved: (() -> Void)?
    
    init(onVideoSaved: (() -> Void)? = nil) {
        self.onVideoSaved = onVideoSaved
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                Spacer().frame(height: 60)
                // 상단 안내 텍스트
                VStack(spacing: 16) {
                    Text("Would you like to\ncapture this moment\nin your memory?")
                        .font(.system(size: 20, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                    Text("Just one memory can be stored every day.")
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
                Spacer()
                // 중앙 카메라 프리뷰 + 십자선
                ZStack {
                    CrosshairView()
                    CameraPreviewView(session: viewModel.session)
                        .frame(width: 100, height: 190)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.white.opacity(0.5), lineWidth: 2)
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: 360)
                Spacer()
                // 하단 촬영 버튼
                Button(action: {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
                    }
                }) {
                    ZStack {
                        Circle()
                            .stroke(Color.white, lineWidth: 6)
                            .frame(width: 100, height: 100)
                        Circle()
                            .stroke(Color.black, lineWidth: 2)
                            .frame(width: 88, height: 88)
                        Circle()
                            .fill(viewModel.isRecording ? Color.red : Color.white)
                            .frame(width: 80, height: 80)
                    }
                }
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
            viewModel.onDismiss = {
                presentationMode.wrappedValue.dismiss()
            }
            viewModel.onVideoSaved = onVideoSaved
        }
    }
}

// 십자선 뷰
struct CrosshairView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            Path { path in
                // 세로선
                path.move(to: CGPoint(x: width/2, y: 0))
                path.addLine(to: CGPoint(x: width/2, y: height))
                // 가로선
                path.move(to: CGPoint(x: 0, y: height/2))
                path.addLine(to: CGPoint(x: width, y: height/2))
            }
            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
            .foregroundColor(Color.white.opacity(0.5))
        }
        .allowsHitTesting(false)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.yellow
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.backgroundColor = UIColor.black.cgColor
        
        view.layer.addSublayer(previewLayer)
        
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
                previewLayer.frame = uiView.bounds
            }
        }
    }
} 
