import Foundation
import AVFoundation
import CoreImage

class FilteredVideoRecorder: NSObject {
    private var assetWriter: AVAssetWriter?
    private var videoWriterInput: AVAssetWriterInput?
    private var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor?
    private let context = CIContext()
    private var colorControlsFilter: CIFilter?
    private var bloomFilter: CIFilter?
    private var grainGenerator: CIFilter?
    private var grainMonochrome: CIFilter?
    private var grainBlend: CIFilter?
    private var isRecording = false
    
    override init() {
        super.init()
        setupFilmFilters()
    }
    
    private func setupFilmFilters() {
        // 미묘한 색감 조절 - 선명하게 유지
        colorControlsFilter = CIFilter(name: "CIColorControls")
        colorControlsFilter?.setValue(1.05, forKey: kCIInputSaturationKey) // 약간만 채도 증가
        colorControlsFilter?.setValue(1.02, forKey: kCIInputContrastKey) // 미세한 콘트라스트 증가
        colorControlsFilter?.setValue(0.0, forKey: kCIInputBrightnessKey) // 밝기는 그대로
        
        // 빛 번짐 효과 (블룸)
        bloomFilter = CIFilter(name: "CIBloom")
        bloomFilter?.setValue(0.3, forKey: kCIInputRadiusKey) // 번짐 반지름
        bloomFilter?.setValue(0.15, forKey: kCIInputIntensityKey) // 번짐 강도
        
        // ISO 800 필름 그레인
        grainGenerator = CIFilter(name: "CIRandomGenerator")
        
        grainMonochrome = CIFilter(name: "CIColorMonochrome")
        grainMonochrome?.setValue(CIColor.white, forKey: kCIInputColorKey)
        grainMonochrome?.setValue(0.7, forKey: kCIInputIntensityKey)
        
        grainBlend = CIFilter(name: "CISoftLightBlendMode")
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
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        let rotatedCiImage = ciImage.oriented(.right)
        
        // 필터 체인 적용
        var currentImage = rotatedCiImage
        
        // 1. 미묘한 색감 조절
        if let colorFilter = colorControlsFilter {
            colorFilter.setValue(currentImage, forKey: kCIInputImageKey)
            if let output = colorFilter.outputImage {
                currentImage = output
            }
        }
        
        // 2. 빛 번짐 효과 (블룸)
        if let bloom = bloomFilter {
            bloom.setValue(currentImage, forKey: kCIInputImageKey)
            if let output = bloom.outputImage {
                currentImage = output
            }
        }
        
        // 3. ISO 800 필름 그레인 추가
        if let grainGen = grainGenerator,
           let grainMono = grainMonochrome,
           let grainBlendFilter = grainBlend {
            
            if let grainImage = grainGen.outputImage {
                // 노이즈를 흑백으로 변환
                grainMono.setValue(grainImage, forKey: kCIInputImageKey)
                
                if let monoGrain = grainMono.outputImage {
                    // 투명도 조절을 위한 색상 매트릭스 적용
                    let scaledGrain = monoGrain.applyingFilter("CIColorMatrix", parameters: [
                        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.08) // ISO 800 수준의 그레인 강도
                    ])
                    
                    // 소프트 라이트 블렌드로 자연스럽게 합성
                    grainBlendFilter.setValue(scaledGrain, forKey: kCIInputBackgroundImageKey)
                    grainBlendFilter.setValue(currentImage, forKey: kCIInputImageKey)
                    
                    if let output = grainBlendFilter.outputImage {
                        currentImage = output
                    }
                }
            }
        }
        
        guard let pixelBufferPool = pixelBufferAdaptor.pixelBufferPool else {
            return
        }
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let outputPixelBuffer = pixelBuffer else {
            return
        }
        
        context.render(currentImage, to: outputPixelBuffer)
        
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
