import Foundation
import SceneKit
import Photos

struct Star: Identifiable {
    let id: String
    let asset: PHAsset
    let position: SCNVector3
    let createdAt: Date
    
    init(asset: PHAsset, position: SCNVector3) {
        self.id = asset.localIdentifier
        self.asset = asset
        self.position = position
        self.createdAt = asset.creationDate ?? Date()
    }
    
    func getVideoURL(completion: @escaping (URL?) -> Void) {
        let options = PHVideoRequestOptions()
        options.version = .current
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { asset, _, _ in
            if let urlAsset = asset as? AVURLAsset {
                completion(urlAsset.url)
            } else {
                completion(nil)
            }
        }
    }
}
