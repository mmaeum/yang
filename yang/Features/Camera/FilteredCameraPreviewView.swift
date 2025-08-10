import SwiftUI
import AVFoundation
import Metal
import MetalKit

struct FilteredCameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession
    @State private var videoOutput: AVCaptureVideoDataOutput?
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.backgroundColor = UIColor.black
        mtkView.delegate = context.coordinator
        mtkView.framebufferOnly = false
        mtkView.colorPixelFormat = .bgra8Unorm
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "videoQueue"))
        
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
            self.videoOutput = videoOutput
        }
        
        context.coordinator.setupRenderer(mtkView: mtkView)
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MTKViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
        private var renderer: VideoFilterRenderer?
        private var mtkView: MTKView?
        
        func setupRenderer(mtkView: MTKView) {
            self.mtkView = mtkView
            self.renderer = VideoFilterRenderer()
        }
        
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            
        }
        
        func draw(in view: MTKView) {
            
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let mtkView = mtkView,
                  let renderer = renderer,
                  let drawable = mtkView.currentDrawable else {
                return
            }
            
            connection.videoRotationAngle = 180
            
            renderer.renderFrame(sampleBuffer: sampleBuffer, to: drawable.texture)
            
            DispatchQueue.main.async {
                drawable.present()
            }
        }
    }
}
