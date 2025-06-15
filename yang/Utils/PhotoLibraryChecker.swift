import Foundation
import Photos

class PhotoLibraryChecker {
    static func checkForTodayVideosInYangFolder(completion: @escaping (Bool) -> Void) {
        // 사진첩 권한 확인
        let status = PHPhotoLibrary.authorizationStatus()
        
        guard status == .authorized || status == .limited else {
            if status == .notDetermined {
                PHPhotoLibrary.requestAuthorization { newStatus in
                    if newStatus == .authorized || newStatus == .limited {
                        performVideoCheck(completion: completion)
                    } else {
                        completion(false)
                    }
                }
            } else {
                completion(false)
            }
            return
        }
        
        performVideoCheck(completion: completion)
    }
    
    private static func performVideoCheck(completion: @escaping (Bool) -> Void) {
        // 앨범에서 "yang" 폴더 찾기
        let albumFetchOptions = PHFetchOptions()
        albumFetchOptions.predicate = NSPredicate(format: "title = %@", "yang")
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: albumFetchOptions)
        
        var hasVideo = false
        
        if albums.count > 0 {
            let yangAlbum = albums.firstObject!
            
            // 오늘 날짜의 시작과 끝 시간 계산
            let calendar = Calendar.current
            let now = Date()
            let startOfDay = calendar.startOfDay(for: now)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            
            // yang 폴더에서 오늘 찍은 비디오 찾기
            let videoFetchOptions = PHFetchOptions()
            videoFetchOptions.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [
                NSPredicate(format: "mediaType = %d", PHAssetMediaType.video.rawValue),
                NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay as NSDate)
            ])
            videoFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            
            let videos = PHAsset.fetchAssets(in: yangAlbum, options: videoFetchOptions)
            hasVideo = videos.count > 0
            
            print("오늘 찍은 비디오 개수: \(videos.count)")
        } else {
            print("yang 폴더를 찾을 수 없습니다.")
        }
        
        completion(hasVideo)
    }
} 