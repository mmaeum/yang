import Foundation
import AVFoundation
import Metal
import MetalKit
import CoreImage

class VideoFilterRenderer: NSObject {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let context: CIContext
    private var sepiaFilter: CIFilter?
    
    override init() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            fatalError("Metal is not available")
        }
        
        self.device = device
        self.commandQueue = commandQueue
        self.context = CIContext(mtlDevice: device)
        
        super.init()
        
        setupFilter()
    }
    
    private func setupFilter() {
        sepiaFilter = CIFilter(name: "CISepiaTone")
        sepiaFilter?.setValue(0.8, forKey: kCIInputIntensityKey)
    }
    
    func renderFrame(sampleBuffer: CMSampleBuffer, to metalTexture: MTLTexture) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let sepiaFilter = sepiaFilter,
              let commandBuffer = commandQueue.makeCommandBuffer() else {
            return
        }
        
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        
        sepiaFilter.setValue(ciImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = sepiaFilter.outputImage else {
            return
        }
        
        let destination = CIRenderDestination(mtlTexture: metalTexture, commandBuffer: commandBuffer)
        destination.isFlipped = false
        
        do {
            try context.startTask(toRender: filteredImage, to: destination)
            commandBuffer.commit()
        } catch {
            print("Failed to render filtered image: \(error)")
        }
    }
}