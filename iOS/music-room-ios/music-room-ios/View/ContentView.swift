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
    
    // MARK: - Cached Artwork Async Image
    
    private func cachedArtworkAsyncImage(
        _ trackName: String?,
        isMainArtwork: Bool = false
    ) -> AsyncImage<_ConditionalContent<Image, Image>> {
        let url: URL? = {
            guard
                let trackName = trackName
            else {
                return nil
            }
            
            return musicKit.artworkURLs[trackName]

        }()
        
        guard
            let cachedImage = viewModel.cachedArtworkImage(url, shouldPickColor: isMainArtwork)
        else {
            if let trackName = trackName, url == nil {
                musicKit.requestUpdatedSearchResults(for: trackName)
            }
            
            return AsyncImage(url: url) { image in
                { () -> Image in
                    viewModel.processArtwork(image, url)
                    
                    return image
                        .resizable()
                }()
            } placeholder: {
                Image(uiImage: UIImage())
                    .resizable()
            }
        }
        
        return AsyncImage(url: nil) { _ in
            Image(uiImage: cachedImage)
                .resizable()
        } placeholder: {
            Image(uiImage: cachedImage)
                .resizable()
        }
    }
    
    var body: some View {
        
        // MARK: - Artwork
        
        let artworkView = cachedArtworkAsyncImage(viewModel.track?.name, isMainArtwork: true)
        
        // MARK: - Main Layout
        
        ZStack {
            if let proxyColor = viewModel.artworkProxyPrimaryColor {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                proxyColor,
                                viewModel.gradient.backgroundColor,
                            ],
                            center: viewModel.gradient.center,
                            startRadius: viewModel.gradient.startRadius,
                            endRadius: viewModel.gradient.endRadius
                        )
                    )
                    .blur(radius: viewModel.gradient.blurRadius)
                    .overlay(viewModel.gradient.material)
                    .edgesIgnoringSafeArea(viewModel.gradient.ignoresSafeAreaEdges)
                    .transition(viewModel.gradient.transition)
            } else {
                Rectangle()
                    .fill(
                        RadialGradient(
                            colors: [
                                viewModel.artworkPrimaryColor,
                                viewModel.gradient.backgroundColor,
                            ],
                            center: viewModel.gradient.center,
                            startRadius: viewModel.gradient.startRadius,
                            endRadius: viewModel.gradient.endRadius
                        )
                    )
                    .blur(radius: viewModel.gradient.blurRadius)
                    .overlay(viewModel.gradient.material)
                    .edgesIgnoringSafeArea(viewModel.gradient.ignoresSafeAreaEdges)
                    .transition(viewModel.gradient.transition)
            }
            
            VStack(alignment: .center, spacing: 64) {
                switch viewModel.interfaceState {
                    
                // MARK: - Player Layout
                    
                case .player:
                    
                    ZStack(alignment: .topLeading) {
                        GeometryReader { geometry in
                            viewModel.playerArtworkPlaceholder(geometry)
                                .aspectRatio(1, contentMode: .fit)
                                .foregroundColor(musicKit.artworkURLs[viewModel.track?.name ?? ""] == nil ? .gray : .clear)
                        }
                        
                        artworkView
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(8)
                            .shadow(color: Color(white: 0, opacity: 0.3), radius: 4, x: 0, y: 4)
                    }
                    .padding(viewModel.playerArtworkPadding)
                    .transition(
                        .scale(
                            scale: viewModel.artworkScale,
                            anchor: .topLeading
                        )
                        .combined(with: .opacity)
                    )
                    
                    VStack(alignment: .leading, spacing: 48) {
                        Text(viewModel.track?.name ?? "Not Playing")
                            .foregroundColor(viewModel.primaryControlsColor)
                            .font(.headline)
                            .dynamicTypeSize(.xLarge)
                        
                        VStack(spacing: 8) {
                            ProgressView(value: 0.5, total: 1)
                                .tint(viewModel.secondaryControlsColor)
                            
                            HStack {
                                Text("--:--")
                                    .foregroundColor(viewModel.secondaryControlsColor)
                                
                                Spacer()
                                
                                Text("--:--")
                                    .foregroundColor(viewModel.secondaryControlsColor)
                            }
                        }
                    }
                    .transition(
                        .move(edge: .top)
                        .combined(with: .opacity)
                    )
                    
                // MARK: - Playlist Layout
                    
                case .playlist:
                    
                    HStack(alignment: .center, spacing: 12) {
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 4, style: .circular)
                                .foregroundColor(musicKit.artworkURLs[viewModel.track?.name ?? ""] == nil ? .gray : .clear)
                            
                            artworkView
                                .cornerRadius(4)
                        }
                        .frame(
                            width: viewModel.playlistArtworkWidth,
                            height: viewModel.playlistArtworkWidth
                        )
                        
                        Spacer()
                    }
                    .padding(.bottom, -48)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
                    
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.playlistTracks) { track in
                            HStack {
                                ZStack(alignment: .topLeading) {
                                    RoundedRectangle(cornerRadius: 4, style: .circular)
                                        .foregroundColor(musicKit.artworkURLs[track.name] == nil ? .gray : .clear)
                                    
                                    cachedArtworkAsyncImage(track.name)
                                        .cornerRadius(4)
                                }
                                .frame(
                                    width: viewModel.playlistQueueArtworkWidth,
                                    height: viewModel.playlistQueueArtworkWidth
                                )
                                
                                Text(track.name)
                                    .foregroundColor(viewModel.primaryControlsColor)
                                    .padding(.vertical, 12)
                                
                                Spacer()
                                
                                Button {
                                    
                                } label: {
                                    Image(systemName: "text.insert")
                                        .foregroundColor(viewModel.primaryControlsColor)
                                }
                            }
                        }
                    }
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
                    
                    Spacer()
                }
                
                // MARK: - Control Bar
                
                HStack(alignment: .center, spacing: 64) {
                    Button {
                        Task {
                            let track = Track(name: "One Republic — Let's Hurt Tonight")
                            
                            musicKit.artworkURLs[track.name] = URL(string: "https://is4-ssl.mzstatic.com/image/thumb/Music125/v4/00/26/2c/00262ccd-0ac1-6f1b-8dda-fe96959fc334/21UMGIM70368.rgb.jpg/1000x1000bb.jpg")
                            
                            viewModel.track = track
                            
                            do {
                                try await api.playerWebSocket?.playPreviousTrack()
                            } catch {
                                debugPrint(error)
                            }
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.primaryControlsColor)
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
                        .foregroundColor(viewModel.primaryControlsColor)
                    }
                    
                    Button {
                        Task {
                            let track = Track(name: "Adele — Skyfall")
                            
                            musicKit.artworkURLs[track.name] = URL(string: "https://is4-ssl.mzstatic.com/image/thumb/Music125/v4/b3/fe/cf/b3fecf76-0359-8e14-0651-4b101fc68a3f/886443673632.jpg/1000x1000bb.jpg")
                            
                            viewModel.track = track
                            
                            do {
                                try await api.playerWebSocket?.playNextTrack()
                            } catch {
                                debugPrint(error)
                            }
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 32))
                            .foregroundColor(viewModel.primaryControlsColor)
                    }
                }
                
                // MARK: - Bottom Bar
                
                HStack(alignment: .center, spacing: 76) {
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
                            .foregroundColor(viewModel.secondaryControlsColor)
                    }
                    
                    Button {
                        print("Settings")
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.secondaryControlsColor)
                    }
                    
                    Button {
                        withAnimation {
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
                                .foregroundColor(viewModel.secondaryControlsColor)
                            
                        case .playlist:
                            Image(systemName: "list.bullet")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(viewModel.secondaryControlsColor)
                                .background(.gray, in: RoundedRectangle(cornerRadius: 2).inset(by: -4))
                            
                        }
                    }
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $authSheet.isShowing, content: {
            
            // MARK: - Sign In Sheet
            
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
                                .foregroundColor(viewModel.primaryControlsColor)
                                .frame(maxWidth: .infinity, maxHeight: 24)
                        } else {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(viewModel.primaryControlsColor)
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
            
            // MARK: - On Appear
            
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
