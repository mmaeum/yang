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
            // 검은색 배경
            Color.black
                .ignoresSafeArea()
            
            VStack {
                Spacer()
                
                // 카메라 프리뷰 (작은 사각형)
                CameraPreviewView(session: viewModel.session)
                    .frame(width: 200, height: 300)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                
                Spacer()
                
                // 안내 텍스트
                VStack(spacing: 8) {
                    Text("Align scene on")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                    
                    Text("the middle of the grid")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }
                .padding(.bottom, 40)
                
                // 촬영 제한 메시지
                Text("Only 1 shot per day")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 20)
                
                // 촬영 컨트롤 버튼들
                HStack(spacing: 60) {    
                    // 촬영 버튼
                    Button(action: {
                        if viewModel.isRecording {
                            viewModel.stopRecording()
                        } else {
                            viewModel.startRecording()
                        }
                    }) {
                        ZStack {
                            // 진행 상황 원형 바 (배경)
                            Circle()
                                .stroke(Color.gray.opacity(0.3), lineWidth: 4)
                                .frame(width: 100, height: 100)
                            
                            // 진행 상황 원형 바 (진행률)
                            if viewModel.isRecording {
                                Circle()
                                    .trim(from: 0, to: CGFloat(1.0 - (viewModel.recordingTimeRemaining / 3.0)))
                                    .stroke(Color.red, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                                    .frame(width: 100, height: 100)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.linear(duration: 0.1), value: viewModel.recordingTimeRemaining)
                            }
                            
                            // 촬영 버튼
                            Circle()
                                .fill(viewModel.isRecording ? Color.red : Color.white)
                                .frame(width: 80, height: 80)
                            
                            if viewModel.isRecording {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 30, height: 30)
                            }
                            
                        }
                    }
                    
                }
                .padding(.bottom, 30)
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

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
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
