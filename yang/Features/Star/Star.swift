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
    
    // 밝기 계산: 최신일수록 밝고(1.0), 오래될수록 어둡게(0.1) - 더 드라마틱한 차이
    var brightness: Float {
        let now = Date()
        let timeInterval = now.timeIntervalSince(createdAt)
        
        // 14일(1209600초)을 기준으로 밝기 계산 - 더 짧은 기간으로 더 극적인 변화
        let maxAge: TimeInterval = 14 * 24 * 60 * 60 // 14일
        let normalizedAge = min(timeInterval / maxAge, 1.0)
        
        // 비선형 함수를 사용해서 더 극적인 밝기 변화
        // 최신일수록 밝고(1.0), 오래될수록 어둡게(0.1)
        let exponentialDecay = pow(normalizedAge, 2.0) // 제곱 함수로 더 빠른 감소
        return Float(1.0 - (exponentialDecay * 0.9))
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
