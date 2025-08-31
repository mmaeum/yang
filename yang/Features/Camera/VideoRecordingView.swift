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
                HeaderSection()
                Spacer()
                CameraSection(session: viewModel.session)
                Spacer()
                RecordingButton(isRecording: viewModel.isRecording) {
                    if viewModel.isRecording {
                        viewModel.stopRecording()
                    } else {
                        viewModel.startRecording()
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

struct HeaderSection: View {
    var body: some View {
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
    }
}

struct CameraSection: View {
    let session: AVCaptureSession
    
    var body: some View {
        ZStack {
            CameraPreviewView(session: session)
                .frame(width: 90, height: 160)
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 2)
                )
            CrosshairView()
        }
        .frame(maxWidth: .infinity, maxHeight: 360)
    }
}

struct RecordingButton: View {
    let isRecording: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            if isRecording {
                RecordingActiveView()
            } else {
                RecordingInactiveView()
            }
        }
    }
}

struct RecordingInactiveView: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white, lineWidth: 4)
                .frame(width: 90, height: 90)
            Circle()
                .stroke(Color.black, lineWidth: 4)
                .frame(width: 78, height: 78)
            Circle()
                .fill(Color.white)
                .frame(width: 70, height: 70)
        }
    }
}

struct RecordingActiveView: View {
    @State private var progress: CGFloat = 0.0
    @State private var timeRemaining: Double = 3.0
    
    var body: some View {
        ZStack {
            // 배경 원 (연한 색)
            Circle()
                .stroke(Color.white.opacity(0.3), lineWidth: 4)
                .frame(width: 90, height: 90)
            
            // Progress 원 (빨간색)
            Circle()
                .trim(from: 0.0, to: progress)
                .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 90, height: 90)
                .rotationEffect(.degrees(-90))
            
            // 내부 원과 타이머 텍스트
            ZStack {
                Circle()
                    .fill(Color(red: 1.0, green: 0.0, blue: 0.4)) // FF0066
                    .frame(width: 70, height: 70)
                
                VStack(spacing: 2) {
                    Text("REC")
                        .font(.system(size: 15, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(String(format: "%.2f", timeRemaining))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 3.0)) {
                progress = 1.0
            }
            
            // 타이머 시작
            Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { timer in
                if timeRemaining > 0 {
                    timeRemaining -= 0.01
                } else {
                    timer.invalidate()
                    timeRemaining = 0.0
                }
            }
        }
    }
}

struct CrosshairView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            let centerX = width / 2
            let centerY = height / 2
            
            ZStack {
                // 세로선 그라데이션
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0), location: 0),
                        .init(color: Color.white.opacity(0.3), location: 0.35),
                        .init(color: Color.white.opacity(1), location: 0.45),
                        .init(color: Color.white.opacity(1), location: 0.55),
                        .init(color: Color.white.opacity(0.3), location: 0.65),
                        .init(color: Color.white.opacity(0), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .mask(
                    Path { path in
                        path.move(to: CGPoint(x: centerX, y: 0))
                        path.addLine(to: CGPoint(x: centerX, y: height))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                )
                
                // 가로선 그라데이션
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0), location: 0),
                        .init(color: Color.white.opacity(0.3), location: 0.35),
                        .init(color: Color.white.opacity(1), location: 0.45),
                        .init(color: Color.white.opacity(1), location: 0.55),
                        .init(color: Color.white.opacity(0.3), location: 0.65),
                        .init(color: Color.white.opacity(0), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .mask(
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: centerY))
                        path.addLine(to: CGPoint(x: width, y: centerY))
                    }
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view: UIView = UIView()
        view.backgroundColor = UIColor.black
        
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
