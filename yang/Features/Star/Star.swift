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
    
    // 밝기 계산: 최신일수록 밝고(1.0), 오래될수록 어둡게(0.3)
    var brightness: Float {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)
        
        // 30일(2592000초)을 기준으로 밝기 계산
        let maxAge: TimeInterval = 30 * 24 * 60 * 60 // 30일
        let normalizedAge = min(timeInterval / maxAge, 1.0)
        
        // 최신일수록 밝고(1.0), 오래될수록 어둡게(0.3)
        return Float(1.0 - (normalizedAge * 0.7))
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
