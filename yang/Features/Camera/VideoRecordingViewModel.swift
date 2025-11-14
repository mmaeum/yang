import SwiftUI
import AVFoundation
import UIKit
import Photos

class VideoRecordingViewModel: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTimeRemaining: Double = 3.0
    let session = AVCaptureSession()
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var filteredRecorder: FilteredVideoRecorder?
    private var currentCamera: AVCaptureDevice?
    private var recordingTimer: Timer?
    private var startTime: CMTime?
    private let sessionQueue = DispatchQueue(label: "com.mmaeum.yang.camera.session", qos: .userInitiated)
    private let sessionQueueKey = DispatchSpecificKey<Void>()
    private let pushManager: PushManager
    var onDismiss: (() -> Void)?
    var onVideoSaved: (() -> Void)?
    
    init(pushManager: PushManager = .shared) {
        self.pushManager = pushManager
        super.init()
        sessionQueue.setSpecific(key: sessionQueueKey, value: ())
        setupNotifications()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupNotifications() {
        // 앱이 포그라운드로 돌아올 때 카메라 세션 재시작
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(willEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )

        // 앱이 백그라운드로 갈 때 카메라 세션 중지
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
    }

    @objc private func willEnterForeground() {
        // 녹화 중이 아닐 때만 세션 재시작
        guard !isRecording else { return }
        sessionQueue.async { [weak self] in
            self?.restartSession()
        }
    }

    @objc private func didEnterBackground() {
        // 백그라운드에서 카메라 세션 중지 (리소스 절약)
        guard !isRecording else { return }
        sessionQueue.async { [weak self] in
            self?.stopSessionIfNeeded()
        }
    }

    private func restartSession() {
        assertOnSessionQueue()
        stopSessionIfNeeded()
        startSessionIfNeeded()
        print("Camera session restarted from background")
    }

    private func startSessionIfNeeded() {
        assertOnSessionQueue()
        guard !session.isRunning else { return }
        session.startRunning()
        print("Camera session started running")
    }

    private func stopSessionIfNeeded() {
        assertOnSessionQueue()
        guard session.isRunning else { return }
        session.stopRunning()
        print("Camera session stopped")
    }

    private func assertOnSessionQueue() {
        dispatchPrecondition(condition: .onQueue(sessionQueue))
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
            sessionQueue.async { [weak self] in
                self?.setupSession()
            }
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { [weak self] status in
                if status == .authorized || status == .limited {
                    self?.sessionQueue.async { [weak self] in
                        self?.setupSession()
                    }
                }
            }
        default:
            print("Photo library access denied")
            sessionQueue.async { [weak self] in
                self?.setupSession()
            }
        }
    }
    
    private func setupSession() {
    assertOnSessionQueue()

        stopSessionIfNeeded()

        session.beginConfiguration()

        // 기존 입력/출력 제거
        session.inputs.forEach { session.removeInput($0) }
        session.outputs.forEach { session.removeOutput($0) }

    videoDataOutput = nil

        // 세션 품질 설정 - HD로 변경 (가능하면)
        if session.canSetSessionPreset(.hd1920x1080) {
            session.sessionPreset = .hd1920x1080
        } else if session.canSetSessionPreset(.high) {
            session.sessionPreset = .high
        }

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

        // 필터링을 위한 비디오 데이터 출력 설정
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        dataOutput.alwaysDiscardsLateVideoFrames = false
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoDataQueue"))

        if session.canAddOutput(dataOutput) {
            session.addOutput(dataOutput)
            if let connection = dataOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                } else if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            videoDataOutput = dataOutput
            print("Video data output added successfully")
        }

        // 필터링된 비디오 레코더 초기화
        filteredRecorder = FilteredVideoRecorder()

        session.commitConfiguration()

        startSessionIfNeeded()
    }
    
    func startRecording() {
        guard let filteredRecorder = filteredRecorder else { return }
        
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let fileUrl = paths[0].appendingPathComponent("video_\(Date().timeIntervalSince1970).mov")
        
        filteredRecorder.startRecording(to: fileUrl)
        isRecording = true
        recordingTimeRemaining = 3.0
        startTime = CMTime.zero
        
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
        isRecording = false
        recordingTimeRemaining = 3.0
        
        filteredRecorder?.stopRecording { [weak self] outputURL in
            guard let self = self, let outputURL = outputURL else {
                print("Failed to stop recording")
                return
            }
            
            print("Filtered video recorded to: \(outputURL)")
            self.saveVideoToYangAlbum(videoURL: outputURL)
        }
    }
    
    func switchCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self,
                  let currentCamera = self.currentCamera else { return }

            self.assertOnSessionQueue()

            let newPosition: AVCaptureDevice.Position = currentCamera.position == .back ? .front : .back

            guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
                  let newInput = try? AVCaptureDeviceInput(device: newCamera) else {
                return
            }

            self.session.beginConfiguration()

            // 기존 비디오 입력 제거
            let currentVideoInputs = self.session.inputs.compactMap { $0 as? AVCaptureDeviceInput }.filter { $0.device.hasMediaType(.video) }
            currentVideoInputs.forEach { self.session.removeInput($0) }

            // 새로운 비디오 입력 추가
            if self.session.canAddInput(newInput) {
                self.session.addInput(newInput)
                self.currentCamera = newCamera
            }

            // 오디오 입력이 없는 경우 다시 추가
            if !self.session.inputs.contains(where: { ($0 as? AVCaptureDeviceInput)?.device.hasMediaType(.audio) == true }),
               let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               self.session.canAddInput(audioInput) {
                self.session.addInput(audioInput)
            }

            // 비디오 출력 방향 재설정
            if let dataOutput = self.videoDataOutput,
               let connection = dataOutput.connection(with: .video),
               connection.isVideoStabilizationSupported {
                connection.preferredVideoStabilizationMode = .auto
            }

            if let dataOutput = self.videoDataOutput,
               let connection = dataOutput.connection(with: .video) {
                if #available(iOS 17.0, *) {
                    if connection.isVideoRotationAngleSupported(90) {
                        connection.videoRotationAngle = 90
                    }
                } else if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
            }

            self.session.commitConfiguration()
        }
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
                        self?.handleSuccessfulVideoSave(videoURL: videoURL)
                    } else {
                        print("Failed to save video to yang album: \(error?.localizedDescription ?? "Unknown error")")
                        // 실패해도 카메라 세션 종료
                        self?.sessionQueue.async { [weak self] in
                            self?.stopSessionIfNeeded()
                        }
                        // 실패해도 화면 닫기
                        self?.onDismiss?()
                        self?.onVideoSaved?()
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

extension VideoRecordingViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isRecording else { return }
        
        let presentationTime: CMTime
        if let startTime = startTime, startTime == CMTime.zero {
            self.startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            presentationTime = CMTime.zero
        } else if let startTime = startTime {
            presentationTime = CMTimeSubtract(CMSampleBufferGetPresentationTimeStamp(sampleBuffer), startTime)
        } else {
            presentationTime = CMTime.zero
        }
        
        filteredRecorder?.recordFrame(sampleBuffer: sampleBuffer, at: presentationTime)
    }
}

private extension VideoRecordingViewModel {
    func handleSuccessfulVideoSave(videoURL: URL) {
        print("Video saved to yang album successfully")
        try? FileManager.default.removeItem(at: videoURL)
        sessionQueue.async { [weak self] in
            self?.stopSessionIfNeeded()
        }
        onDismiss?()
        onVideoSaved?()
        scheduleStarReminderChain()
    }
    
    func scheduleStarReminderChain() {
        Task {
            await pushManager.scheduleStarReminders(startingFrom: Date())
        }
    }
}
