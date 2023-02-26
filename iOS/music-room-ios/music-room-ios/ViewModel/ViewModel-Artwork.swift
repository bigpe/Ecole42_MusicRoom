import SwiftUI

extension ViewModel {
    
    func prepareArtwork(
        _ trackName: String?
    ) async {
        guard let trackName = trackName else { return }
        
        var url = musicKit.artworkURLs[trackName]
        
        if url == nil {
            url = await musicKit.requestUpdatedSearchResults(for: trackName)
        }
        
        processArtwork(
            trackName: trackName,
            url: url,
            shouldChangeColor: false
        )
    }
    
    @MainActor
    func artworkImage(
        _ trackName: String?,
        geometry: GeometryProxy? = nil
    ) -> Image {
        
        if let geometry = geometry {
            playerArtworkWidth = geometry.size.width
        }
        
        guard let trackName = trackName else {
            return Image(uiImage: placeholderArtworkImage)
                .resizable()
        }
        
        let url = musicKit.artworkURLs[trackName]
        
        guard
            let cachedImage = cachedArtworkImage(trackName, shouldPickColor: true)
        else {
            if url == nil {
                Task {
                    await musicKit.requestUpdatedSearchResults(for: trackName)
                }
            }
            
            processArtwork(
                trackName: trackName,
                url: url,
                shouldChangeColor: true
            )
            
            return artworks[trackName, default: Image(uiImage: placeholderArtworkImage)]
                .resizable()
        }
        
        if artworks[trackName] == nil {
            artworks[trackName] = Image(uiImage: cachedImage)
        }
        
        return Image(uiImage: cachedImage)
            .resizable()
    }
    
    func cachedArtworkImage(_ trackName: String, shouldPickColor: Bool = false) -> UIImage? {
        guard
            let cachedImage = ImageManager.cachedImage(trackName)
        else {
            return nil
        }
        
        if shouldPickColor {
            setArtworkColor(artworkColor(cachedImage))
        }
        
        return cachedImage
    }
    
    func artworkColor(_ uiImage: UIImage) -> Color {
        guard
            let inputImage = CIImage(image: uiImage)
        else {
            return artworkPlaceholder.backgroundColor
        }
        
        let extentVector = CIVector(
            x: inputImage.extent.origin.x,
            y: inputImage.extent.origin.y,
            z: inputImage.extent.size.width,
            w: inputImage.extent.size.height
        )
        
        guard
            let filter = CIFilter(
                name: "CIAreaAverage",
                parameters: [
                    kCIInputImageKey: inputImage,
                    kCIInputExtentKey: extentVector,
                ]
            ),
            let outputImage = filter.outputImage
        else {
            return artworkPlaceholder.backgroundColor
        }
        
        var bitmap = [UInt8](repeating: 0, count: 4)
        
        let context = CIContext(options: [.workingColorSpace: kCFNull as Any])
        
        context.render(
            outputImage,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        
        let uiColor = UIColor(
            red: CGFloat(bitmap[0]) / 255,
            green: CGFloat(bitmap[1]) / 255,
            blue: CGFloat(bitmap[2]) / 255,
            alpha: CGFloat(bitmap[3]) / 255
        )
        
        return Color(uiColor: uiColor)
    }
    
    func setArtworkColor(_ color: Color) {
        guard color != artworkPrimaryColor else { return }
        
        artworkProxyPrimaryColor = nil
        
        DispatchQueue.main.async { [weak self] in
            withAnimation(.easeOut(duration: 0.75)) {
                self?.artworkProxyPrimaryColor = color
                self?.artworkPrimaryColor = color
            }
        }
    }
    
    func processArtwork(
        trackName: String,
        url: URL?,
        shouldChangeColor: Bool = false
    ) {
        func add(_ artwork: UIImage? = nil, forURL url: URL) async throws {
            let image: UIImage = try await {
                guard
                    let artwork
                else {
                    return try await ImageManager.downloadImage(trackName, url: url)
                }
                
                return artwork
            }()
            
            Task { @MainActor in
                if artworks.count >= Self.artworksCapacity / 2 {
                    artworks.removeAll(keepingCapacity: true)
                }
                
                artworks[trackName] = Image(uiImage: image)
            }
        }
        
        guard let url = url else { return }
        
        guard
            let cachedImage = ImageManager.cachedImage(trackName)
        else {
            Task {
                try await add(nil, forURL: url)
            }
            
            return
        }
        
        Task {
            try await add(cachedImage, forURL: url)
        }
        
        if shouldChangeColor {
            setArtworkColor(artworkColor(cachedImage))
        }
    }
}
