import SwiftUI
import AVFoundation
import UIKit

struct CameraView: View {
    @StateObject private var camera = CameraModel()
    
    var body: some View {
        ZStack {
            CameraPreview(camera: camera)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Spacer()
                
                HStack {
                    Button(action: {
                        camera.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        camera.takePicture()
                    }) {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 65, height: 65)
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 2)
                                    .frame(width: 75, height: 75)
                            )
                    }
                    .padding()
                    
                    Spacer()
                    
                    Button(action: {
                        // 갤러리 버튼 액션
                    }) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.5))
                            .clipShape(Circle())
                    }
                    .padding()
                }
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            camera.checkPermissions()
        }
    }
}

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var preview: AVCaptureVideoPreviewLayer!
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setUp()
            return
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                }
            }
        case .denied:
            self.alert = true
            return
        default:
            return
        }
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
            let input = try AVCaptureDeviceInput(device: device!)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func takePicture() {
        DispatchQueue.global(qos: .background).async {
            self.output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
            DispatchQueue.main.async {
                withAnimation { self.isTaken.toggle() }
            }
        }
    }
    
    func switchCamera() {
        // 카메라 전환 로직
        session.beginConfiguration()
        
        // 현재 입력 제거
        for input in session.inputs {
            session.removeInput(input)
        }
        
        // 새로운 카메라 입력 추가
        let currentPosition = (session.inputs.first as? AVCaptureDeviceInput)?.device.position ?? .back
        let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
        
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition) {
            do {
                let input = try AVCaptureDeviceInput(device: device)
                if session.canAddInput(input) {
                    session.addInput(input)
                }
            } catch {
                print(error.localizedDescription)
            }
        }
        
        session.commitConfiguration()
    }
}

struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: UIScreen.main.bounds)
        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.frame
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)
        camera.session.startRunning()
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
    }
} 