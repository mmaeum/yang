import SwiftUI
import AVFoundation
import UIKit
import Photos

struct VideoRecordingView: View {
    @StateObject private var viewModel = VideoRecordingViewModel()
    @Environment(\.presentationMode) var presentationMode
    
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
        }
    }
}

class VideoRecordingViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTimeRemaining: Double = 3.0
    let session = AVCaptureSession()
    private var videoOutput: AVCaptureMovieFileOutput?
    private var currentCamera: AVCaptureDevice?
    private var recordingTimer: Timer?
    var onDismiss: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func checkPermissions() {
        // 카메라 권한 확인
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            checkPhotoLibraryPermission()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    self?.checkPhotoLibraryPermission()
                }
            }
        default:
            print("Camera access denied")
            break
        }
    }
    
    private func checkPhotoLibraryPermission() {
        // 사진첩 권한 확인
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized, .limited:
            DispatchQueue.main.async {
                self.setupSession()
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized || status == .limited {
                    DispatchQueue.main.async {
                        self?.setupSession()
                    }
                }
            }
        default:
            print("Photo library access denied")
            DispatchQueue.main.async {
                self.setupSession()
            }
        }
    }
    
    private func setupSession() {
        // 이미 실행 중이면 중지
        if session.isRunning {
            session.stopRunning()
        }
        
        // 기존 입력/출력 제거
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }
        
        session.beginConfiguration()
        
        // 세션 품질 설정
        session.sessionPreset = .medium
        
        // 비디오 입력 설정
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Failed to get video device")
            session.commitConfiguration()
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                currentCamera = videoDevice
                print("Video input added successfully")
            } else {
                print("Cannot add video input")
            }
        } catch {
            print("Error creating video input: \(error)")
            session.commitConfiguration()
            return
        }
        
        // 오디오 입력 설정
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    print("Audio input added successfully")
                }
            } catch {
                print("Error creating audio input: \(error)")
            }
        }
        
        // 비디오 출력 설정
        let movieOutput = AVCaptureMovieFileOutput()
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            videoOutput = movieOutput
            print("Movie output added successfully")
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
            DispatchQueue.main.async {
                print("Camera session started running")
            }
        }
    }
    
    func startRecording() {
        guard let videoOutput = videoOutput else { return }
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
        videoOutput.startRecording(to: fileUrl, recordingDelegate: self)
        isRecording = true
        recordingTimeRemaining = 3.0
        
        // 3초 타이머 시작
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            
            self.recordingTimeRemaining -= 0.1
            
            if self.recordingTimeRemaining <= 0 {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        recordingTimer?.invalidate()
        recordingTimer = nil
        videoOutput?.stopRecording()
        isRecording = false
        recordingTimeRemaining = 3.0
    }
    
    func switchCamera() {
        guard let currentCamera = currentCamera else { return }
        
        let newPosition: AVCaptureDevice.Position = currentCamera.position == .back ? .front : .back
        
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
            return
        }
        
        session.beginConfiguration()
        
        // 기존 비디오 입력 제거
        if let currentInput = session.inputs.first as? AVCaptureDeviceInput {
            session.removeInput(currentInput)
        }
        
        // 새로운 비디오 입력 추가
        if session.canAddInput(newInput) {
            session.addInput(newInput)
            self.currentCamera = newCamera
        }
        
        session.commitConfiguration()
    }
    
    private func saveVideoToYangAlbum(videoURL: URL) {
        // "yang" 앨범 찾기 또는 생성
        findOrCreateYangAlbum { [weak self] album in
            guard let album = album else {
                print("Failed to create or find yang album")
                return
            }
            
            // 비디오를 앨범에 저장
            PHPhotoLibrary.shared().performChanges({
                let assetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
                guard let assetPlaceholder = assetRequest?.placeholderForCreatedAsset else { return }
                
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: album)
                albumChangeRequest?.addAssets([assetPlaceholder] as NSArray)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        print("Video saved to yang album successfully")
                        // 임시 파일 삭제
                        try? FileManager.default.removeItem(at: videoURL)
                        // 화면 닫기
                        self?.onDismiss?()
                    } else {
                        print("Failed to save video to yang album: \(error?.localizedDescription ?? "Unknown error")")
                        // 실패해도 화면 닫기
                        self?.onDismiss?()
                    }
                }
            }
        }
    }
    
    private func findOrCreateYangAlbum(completion: @escaping (PHAssetCollection?) -> Void) {
        let albumName = "yang"
        
        // 기존 앨범 찾기
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let existingAlbum = collections.firstObject {
            completion(existingAlbum)
            return
        }
        
        // 앨범이 없으면 새로 생성
        PHPhotoLibrary.shared().performChanges({
            PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
        }) { success, error in
            if success {
                // 새로 생성된 앨범 찾기
                let newFetchOptions = PHFetchOptions()
                newFetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
                let newCollections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: newFetchOptions)
                completion(newCollections.firstObject)
            } else {
                print("Failed to create yang album: \(error?.localizedDescription ?? "Unknown error")")
                completion(nil)
            }
        }
    }
}

extension VideoRecordingViewModel: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
            return
        }
        
        print("Video recorded to: \(outputFileURL)")
        
        // "yang" 앨범에 비디오 저장
        saveVideoToYangAlbum(videoURL: outputFileURL)
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
