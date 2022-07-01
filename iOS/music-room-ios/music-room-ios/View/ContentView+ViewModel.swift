//
//  ContentView+ViewModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import SwiftUI
import PINCache

extension ContentView {
    
    @MainActor
    class ViewModel: ObservableObject {
        enum InterfaceState {
            case player
            
            case playlist
        }
        
        enum PlayerState {
            case playing, paused
            
            mutating func toggle() {
                self = {
                    switch self {
                    case .playing:
                        return .paused
                        
                    case .paused:
                        return .playing
                    }
                }()
            }
        }
        
        enum ShuffleState {
            case on, off
            
            mutating func toggle() {
                self = {
                    switch self {
                    case .on:
                        return .off
                        
                    case .off:
                        return .on
                    }
                }()
            }
        }
        
        let primaryControlsColor = Color.primary
        
        let secondaryControlsColor = Color.primary.opacity(0.55)
        
        let gradient = (
            backgroundColor: Color.black,
            center: UnitPoint.center,
            startRadius: CGFloat(50),
            endRadius: CGFloat(600),
            blurRadius: CGFloat(150),
            material: Material.ultraThinMaterial,
            transition: AnyTransition.opacity,
            ignoresSafeAreaEdges: Edge.Set.all
            
        )
        
        let playerArtworkPadding = CGFloat(34)
        
        var playerArtworkWidth: CGFloat?
        
        func playerArtworkPlaceholder(_ geometry: GeometryProxy) -> some View {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.playerArtworkWidth = geometry.size.width
            }
            
            return RoundedRectangle(cornerRadius: 8, style: .circular)
        }
        
        let playlistArtworkWidth = CGFloat(64)
        
        let playlistQueueArtworkWidth = CGFloat(40)
        
        var artworkProxyPrimaryColor: Color?
        
        @Published
        var artworkPrimaryColor = Color.gray
        
        func cachedArtworkImage(_ artworkURL: URL?, shouldPickColor: Bool = false) -> UIImage? {
            guard
                let artworkKey = artworkURL?.absoluteString,
                let cachedImage = PINCache.shared.object(forKey: artworkKey) as? UIImage
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
                return .gray
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
                return .gray
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
        
        func processArtwork(_ image: Image, _ artworkURL: URL?) {
            let primaryImageColor: Color = {
                let controller = UIHostingController(rootView: image)
                
                controller.view.frame = CGRect(
                    x: 0,
                    y: .max,
                    width: 1,
                    height: 1
                )
                
                guard
                    let windowScene = UIApplication.shared.connectedScenes.first(where: {
                        $0 is UIWindowScene
                    }) as? UIWindowScene,
                    let rootViewController = windowScene.keyWindow?.rootViewController
                else {
                    return .gray
                }
                
                rootViewController.view.addSubview(controller.view)
                
                let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
                
                controller.view.bounds = CGRect(origin: .zero, size: size)
                controller.view.sizeToFit()
                
                let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds)
                
                let uiImage = renderer.image { rendererContext in
                    controller.view.layer.render(in: rendererContext.cgContext)
                }
                
                if let artworkKey = artworkURL?.absoluteString {
                    PINCache.shared.setObjectAsync(uiImage, forKey: artworkKey)
                }
                
                return artworkColor(uiImage)
            }()
            
            setArtworkColor(primaryImageColor)
        }
        
        var artworkScale: CGFloat {
            guard
                let playerArtworkWidth = playerArtworkWidth
            else {
                return .zero
            }

            switch interfaceState {
            case .player:
                return playlistArtworkWidth / playerArtworkWidth
                
            case .playlist:
                return playerArtworkWidth / playlistArtworkWidth
            }
        }
        
        @Published
        var interfaceState = InterfaceState.player
        
        @Published
        var playerState = PlayerState.paused
        
        @Published
        var shuffleState = ShuffleState.off
        
        @Published
        var track: Track?
        
        @Published
        var playlist: Playlist?
        
        var tracks = [Track]()
        
        var playlistTracks: [Track] {
            return [
                Track(id: 1, name: "Jakarta — One Desire"),
                Track(id: 2, name: "Don Diablo — Silence"),
                Track(id: 3, name: "Adele — Skyfall"),
            ]
            
            (playlist?.tracks ?? [])
                .map { playlistTrack in
                    tracks.first(where: { $0.id == playlistTrack.id }) ?? Track(name: "Unknown")
                }
        }
    }
}
