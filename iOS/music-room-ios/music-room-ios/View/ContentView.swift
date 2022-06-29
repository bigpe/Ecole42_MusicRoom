//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject
    private var viewModel = ViewModel()
    
    @StateObject
    private var authSheet = AuthSheet()
    
    @FocusState
    var focusedField: AuthSheet.Field?
    
    @StateObject
    private var musicKit = MusicKit()
    
    private let api = API()
    
    var body: some View {
        let artworkView = AsyncImage(
            url: musicKit.artworkURL
        ) { phase in
            switch phase {
            case .empty:
                EmptyView()
                
            case .success(let image):
                { () -> Image in
                    let primaryImageColor: Color = {
                        let controller = UIHostingController(rootView: image)
                        
                        controller.view.frame = CGRect(
                            x: 0,
                            y: .max,
                            width: 1,
                            height: 1
                        )
                        
                        UIApplication.shared.windows.first?.rootViewController?.view.addSubview(
                            controller.view
                        )
                        
                        let size = controller.sizeThatFits(in: UIScreen.main.bounds.size)
                        
                        controller.view.bounds = CGRect(origin: .zero, size: size)
                        controller.view.sizeToFit()
                        
                        let renderer = UIGraphicsImageRenderer(bounds: controller.view.bounds)
                        
                        let renderedImage = renderer.image { rendererContext in
                            controller.view.layer.render(in: rendererContext.cgContext)
                        }
                        
                        guard
                            let inputImage = CIImage(image: renderedImage)
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
                        
                        let context = CIContext(options: [.workingColorSpace: kCFNull])
                        
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
                    }()
                    
                    guard primaryImageColor != musicKit.artworkPrimaryColor else {
                        return image
                    }
                    
                    DispatchQueue.main.async {
                        musicKit.artworkPrimaryColor = primaryImageColor
                    }
                    
                    return image
                }()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius({
                        switch viewModel.interfaceState {
                        case .player:
                            return 8
                            
                        case .playlist:
                            return 4
                        }
                    }(), antialiased: true)
                
            case .failure:
                EmptyView()
                
            @unknown default:
                EmptyView()
            }
        }
        
        ZStack {
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [
                            musicKit.artworkPrimaryColor,
                            .black,
                        ],
                        center: .center,
                        startRadius: 50,
                        endRadius: 600
                    )
                )
                .blur(radius: 150)
                .overlay(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.all)
            
            LazyVStack(alignment: .center, spacing: 64) {
                
                switch viewModel.interfaceState {
                    
                case .player:
                    RoundedRectangle(cornerRadius: 8, style: .circular)
                        .aspectRatio(1, contentMode: .fit)
                        .foregroundColor(.gray)
                        .overlay {
                            artworkView
                        }
                        .shadow(color: Color(white: 0, opacity: 0.3), radius: 4, x: 0, y: 4)
                        .padding(32)
                    
                    LazyVStack(alignment: .leading, spacing: 48) {
                        Text(viewModel.track?.name ?? "Not Playing")
                            .foregroundColor(.white)
                            .font(.headline)
                            .dynamicTypeSize(.xLarge)
                        
                        LazyVStack(spacing: 8) {
                            ProgressView(value: 0.5, total: 1)
                                .tint(.white)
                            
                            HStack {
                                Text("--:--")
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                Text("--:--")
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    
                case .playlist:
                    RoundedRectangle(cornerRadius: 4, style: .circular)
                        .size(width: 64, height: 64)
                        .foregroundColor(.gray)
                        .overlay {
                            artworkView
                        }
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(viewModel.playlistTracks) { track in
                                HStack {
                                    Text(track.name)
                                        .foregroundColor(.white)
                                        .padding(.vertical, 12)
                                    
                                    Spacer()
                                    
                                    Button {
                                        
                                    } label: {
                                        Image(systemName: "text.insert")
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    }
                    
                    Spacer()
                }
                
                LazyHStack(alignment: .center, spacing: 64) {
                    Button {
                        Task {
                            musicKit.artworkURL = URL(string: "https://is4-ssl.mzstatic.com/image/thumb/Music125/v4/00/26/2c/00262ccd-0ac1-6f1b-8dda-fe96959fc334/21UMGIM70368.rgb.jpg/1000x1000bb.jpg")
                            
                            viewModel.track = Track(name: "One Republic — Let's Hurt Tonight")
                            
                            do {
                                try await api.playerWebSocket?.playPreviousTrack()
                            } catch {
                                debugPrint(error)
                            }
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        Task {
                            do {
                                switch viewModel.playerState {
                                case .playing:
                                    try await api.playerWebSocket?.pauseTrack()
                                    
                                case .paused:
                                    try await api.playerWebSocket?.playTrack()
                                }
                                
                                viewModel.playerState.toggle()
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        Image(systemName: {
                            switch viewModel.playerState {
                            case .playing:
                                return "pause.fill"
                                
                            case .paused:
                                return "play.fill"
                            }
                        }())
                        .font(.system(size: 48))
                        .foregroundColor(.white)
                    }
                    
                    Button {
                        Task {
                            musicKit.artworkURL = URL(string: "https://is4-ssl.mzstatic.com/image/thumb/Music125/v4/b3/fe/cf/b3fecf76-0359-8e14-0651-4b101fc68a3f/886443673632.jpg/1000x1000bb.jpg")
                            
                            viewModel.track = Track(name: "Adele — Skyfall")
                            
                            do {
                                try await api.playerWebSocket?.playNextTrack()
                            } catch {
                                debugPrint(error)
                            }
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white)
                    }
                }
                
                LazyHStack(alignment: .center, spacing: 76) {
                    Button {
                        Task {
                            do {
                                try await api.playerWebSocket?.shuffle()
                            } catch {
                                debugPrint(error)
                            }
                        }
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        print("Settings")
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        withAnimation(.spring()) {
                            viewModel.interfaceState = {
                                switch viewModel.interfaceState {
                                case .player:
                                    return .playlist
                                    
                                case .playlist:
                                    return .player
                                }
                            }()
                        }
                    } label: {
                        switch viewModel.interfaceState {
                        case .player:
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                            
                        case .playlist:
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(.white)
                                .background(.gray, in: RoundedRectangle(cornerRadius: 2).inset(by: -4))
                            
                        }
                    }
                }
            }
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $authSheet.isShowing, content: {
            VStack(alignment: .leading, spacing: 24) {
                Text("Sign In")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        
                        TextField(text: $authSheet.usernameText) {
                            Text("Username")
                        }
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .username)
                        
                        SecureField("Password", text: $authSheet.passwordText)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .password)
                    }
                    
                    Button {
                        guard !authSheet.isLoading else { return }
                        
                        Task {
                            await MainActor.run {
                                authSheet.isLoading = true
                            }
                            
                            await withCheckedContinuation { continuation in
                                DispatchQueue
                                    .global(qos: .background)
                                    .asyncAfter(deadline: .now() + 1) {
                                        continuation.resume()
                                    }
                            }
                            
                            await MainActor.run {
                                authSheet.isLoading = false
                                authSheet.isShowing = false
                            }
                        }
                    } label: {
                        if !authSheet.isLoading {
                            Text("Continue")
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity, maxHeight: 24)
                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.white)
                                .frame(maxWidth: .infinity, maxHeight: 24)
                        }
                        
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }

            }
            .padding(.horizontal, 16)
            .interactiveDismissDisabled()
        })
        .onAppear {
//            authSheet.isShowing = !api.isAuthorized
            
            if let playerWebSocket = api.playerWebSocket, !playerWebSocket.isSubscribed {
                playerWebSocket
                    .onReceive { event in
                        switch event {
                            
                        case .playTrack:
                            viewModel.playerState = .playing
                            
                        case .playNextTrack:
                            break
                            
                        case .playPreviousTrack:
                            break
                            
                        case .shuffle:
                            viewModel.shuffleState.toggle()
                            
                        case .pauseTrack:
                            viewModel.playerState = .paused
                            
                        case .resumeTrack:
                            viewModel.playerState = .playing
                            
                        case .stopTrack:
                            viewModel.playerState = .paused
                            
                        default:
                            break
                        }
                    }
            }
            
            if let playlistWebSocket = api.playlistWebSocket, !playlistWebSocket.isSubscribed {
                playlistWebSocket
                    .onReceive { event in
                        switch event {
                            
                        case .playlistChanged:
                            break
                            
                        case .playlistsChanged:
                            break
                            
                        case .renamePlaylist:
                            break
                            
                        case .addPlaylist:
                            break
                            
                        case .removePlaylist:
                            break
                            
                        case .addTrack:
                            break
                            
                        case .removeTrack:
                            break
                            
                        }
                    }
            }
        }
    }
}
