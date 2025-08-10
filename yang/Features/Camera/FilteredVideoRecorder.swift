import Foundation
import AVFoundation
import CoreImage

class FilteredVideoRecorder: NSObject {
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private let context = CIContext()
    private var sepiaFilter: CIFilter?
    private var isRecording = false
    
    override init() {
        super.init()
        setupFilter()
    }
    
    private func setupFilter() {
        sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(0.8, forKey: kCIInputIntensityKey)
    }
    
    func startRecording(to outputURL: URL) {
        guard !isRecording else { return }
        
        do {
            assetWriter = try AVAssetWriter(outputURL: outputURL, fileType: .mov)
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1080,
                AVVideoHeightKey: 1920,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000
                ]
            ]
            
            videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            videoWriterInput?.expectsMediaDataInRealTime = true
            
            let pixelBufferAttributes: [String: Any] = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
                kCVPixelBufferWidthKey as String: 1080,
                kCVPixelBufferHeightKey as String: 1920
            ]
            
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(
                assetWriterInput: videoWriterInput!,
                sourcePixelBufferAttributes: pixelBufferAttributes
            )
            
            if let videoWriterInput = videoWriterInput,
               assetWriter?.canAdd(videoWriterInput) == true {
                assetWriter?.add(videoWriterInput)
            }
            
            assetWriter?.startWriting()
            assetWriter?.startSession(atSourceTime: .zero)
            
            isRecording = true
            print("Started filtered video recording")
            
        } catch {
            print("Failed to start recording: \(error)")
        }
    }
    
    func recordFrame(sampleBuffer: CMSampleBuffer, at presentationTime: CMTime) {
        guard isRecording,
              let assetWriter = assetWriter,
              assetWriter.status == .writing,
              let videoWriterInput = videoWriterInput,
              videoWriterInput.isReadyForMoreMediaData,
              let pixelBufferAdaptor = pixelBufferAdaptor,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let sepiaFilter = sepiaFilter else {
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let rotatedCiImage = ciImage.oriented(.right);
        sepiaFilter.setValue(rotatedCiImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = sepiaFilter.outputImage,
              let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            return
        }
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let outputPixelBuffer = pixelBuffer else {
            return
        }
        
        context.render(filteredImage, to: outputPixelBuffer)
        
        pixelBufferAdaptor.append(outputPixelBuffer, withPresentationTime: presentationTime)
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard isRecording else {
            completion(nil)
            return
        }
        
        isRecording = false
        
        videoWriterInput?.markAsFinished()
        
        assetWriter?.finishWriting { [weak self] in
            let outputURL = self?.assetWriter?.outputURL
            self?.cleanup()
            completion(outputURL)
        }
    }
    
    private func cleanup() {
        assetWriter = nil
        videoWriterInput = nil
        pixelBufferAdaptor = nil
    }
}
