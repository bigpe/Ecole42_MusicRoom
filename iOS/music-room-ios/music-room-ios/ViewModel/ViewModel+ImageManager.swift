import SwiftUI
import PINRemoteImage

extension ViewModel {
    enum ImageManager {
        static func cachedImage(_ trackName: String) -> UIImage? {
            guard
                let pinCache = PINRemoteImageManager.shared().pinCache
            else {
                return nil
            }
            
            let memoryCachedImage = pinCache.memoryCache.object(forKey: trackName) as? UIImage
            
            if let memoryCachedImage = memoryCachedImage {
                return memoryCachedImage
            }
            
            guard
                let imageData = pinCache.diskCache.object(forKey: trackName) as? NSData,
                let image = UIImage(data: Data(imageData))
            else {
                return nil
            }
            
            if memoryCachedImage == nil {
                pinCache.memoryCache.setObjectAsync(image, forKey: trackName)
            }
            
            return image
        }
        
        static func downloadImage(_ trackName: String, url: URL) async throws -> UIImage {
            let downloadedImage: UIImage = try await withCheckedThrowingContinuation { continuation in
                PINRemoteImageManager.shared().downloadImage(with: url) { result in
                    guard
                        let image = result.image
                    else {
                        return continuation.resume(throwing: NSError())
                    }
                    
                    return continuation.resume(returning: image)
                }
            }
            
            guard
                let pinCache = PINRemoteImageManager.shared().pinCache
            else {
                return downloadedImage
            }
            
            await pinCache.memoryCache.setObjectAsync(downloadedImage, forKey: trackName)
            
            guard
                let pngImageData = downloadedImage.pngData()
            else {
                return downloadedImage
            }
            
            await pinCache.diskCache.setObjectAsync(NSData(data: pngImageData), forKey: trackName)
            
            return downloadedImage
        }
    }
}
