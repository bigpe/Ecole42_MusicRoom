//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI
import AlertToast
import AVFoundation

struct ContentView: View {
    
    private let api = API()
    
    @StateObject
    private var viewModel = ViewModel()
    
    @StateObject
    private var authViewModel = AuthViewModel()
    
    @StateObject
    private var addPlaylistViewModel = AddPlaylistViewModel()
    
    @StateObject
    private var playlistViewModel = PlaylistViewModel()
    
    @StateObject
    private var musicKit = MusicKit()
    
    // MARK: - Focused Field
    
    @FocusState
    var focusedField: Field?
    
    // MARK: - Cached Artwork Image
    
    func cachedArtworkImage(
        _ trackName: String?,
        geometry: GeometryProxy? = nil,
        isMainArtwork: Bool = false
    ) -> Image {
        
        if let geometry = geometry {
            viewModel.updatePlayerArtworkWidth(geometry)
        }
        
        guard let trackName = trackName else {
            return Image(uiImage: viewModel.placeholderArtworkImage)
                .resizable()
        }
        
        let url = musicKit.artworkURLs[trackName]
        
        guard
            let cachedImage = viewModel.cachedArtworkImage(trackName, shouldPickColor: isMainArtwork)
        else {
            if url == nil {
                musicKit.requestUpdatedSearchResults(for: trackName)
            }
            
            viewModel.processArtwork(
                trackName: trackName,
                url: url,
                shouldChangeColor: isMainArtwork
            )
            
            return Image(uiImage: viewModel.downloadedArtworks[trackName] ?? viewModel.placeholderArtworkImage)
                .resizable()
        }
        
        return Image(uiImage: cachedImage)
            .resizable()
    }
    
    var body: some View {
        
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
//                    VStack(alignment: .leading, spacing: 64) {
                        HStack(alignment: .bottom) {
                            GeometryReader { geometry in
//                                VStack {
//                                    Spacer()
                                    
                                    cachedArtworkImage(
                                        viewModel.currentPlayerContent?.name,
                                        geometry: geometry,
                                        isMainArtwork: true
                                    )
                                    .resizable()
                                    .aspectRatio(1, contentMode: .fit)
                                    .cornerRadius(8)
                                    .shadow(color: Color(white: 0, opacity: 0.3), radius: 8, x: 0, y: 8)
//                                }
                            }
                        }
                            .scaleEffect(
                                viewModel.playerScale,
                                anchor: .center
                            )
                            .transition(
                                .scale(
                                    scale: viewModel.artworkScale,
                                    anchor: viewModel.artworkTransitionAnchor
                                )
                                .combined(with: .opacity)
                                .combined(with: .offset(
                                    x: {
                                        switch viewModel.playerState {
                                        case .paused:
                                            return -viewModel.playlistArtworkWidth / 4

                                        case .playing:
                                            return 0
                                        }
                                    }(),
                                    y: {
                                        switch viewModel.playerState {
                                        case .paused:
                                            return -viewModel.playlistArtworkWidth / 4

                                        case .playing:
                                            return 0
                                        }
                                    }()
                                ))
                            )
                            .animation(
                                .interpolatingSpring(
                                    mass: 1.0,
                                    stiffness: 1,
                                    damping: 1,
                                    initialVelocity: 0.0
                                )
                                .speed(12),
                                value: viewModel.animatingPlayerState
                            )
                        
                        VStack(alignment: .leading, spacing: 32) {
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(viewModel.currentPlayerContent?.title ?? viewModel.placeholderTitle)
                                        .foregroundColor(viewModel.primaryControlsColor)
                                        .font(.title2)
                                        .fontWeight(.medium)
                                    
                                    if let artist = viewModel.currentPlayerContent?.artist {
                                        Text(artist)
                                            .foregroundColor(viewModel.secondaryControlsColor)
                                            .font(.title2)
                                            .fontWeight(.regular)
                                    }
                                }
                                
                                Spacer()
                                
                                Button {
                                    switch viewModel.playerQuality {
                                    case .standard:
                                        viewModel.playerQuality = .highFidelity
                                        
                                    case .highFidelity:
                                        viewModel.playerQuality = .standard
                                    }
                                } label: {
                                    switch viewModel.playerQuality {
                                    case .standard:
                                        Text("HiFi")
                                            .foregroundColor(viewModel.tertiaryControlsColor)
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.semibold)
                                            .dynamicTypeSize(.large)
                                            .background(
                                                RoundedRectangle(cornerRadius: 2)
                                                    .inset(by: -5)
                                                    .strokeBorder(lineWidth: 1.5)
                                                    .foregroundColor(viewModel.tertiaryControlsColor)
                                            )
                                            .padding(5)
                                        
                                    case .highFidelity:
                                        Text("HiFi")
                                            .foregroundColor(viewModel.primaryControlsColor)
                                            .font(.system(.subheadline, design: .rounded))
                                            .fontWeight(.semibold)
                                            .dynamicTypeSize(.large)
                                            .background(
                                                viewModel.primaryControlsColor,
                                                in: RoundedRectangle(cornerRadius: 2)
                                                    .inset(by: -5)
                                            )
                                            .mask(alignment: .center) {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .inset(by: -5)
                                                    .overlay(alignment: .center) {
                                                        Text("HiFi")
                                                            .foregroundColor(viewModel.primaryControlsColor)
                                                            .font(.system(.subheadline, design: .rounded))
                                                            .fontWeight(.semibold)
                                                            .dynamicTypeSize(.large)
                                                            .blendMode(.destinationOut)
                                                    }
                                            }
                                            .padding(5)
                                    }
                                }
                            }
                            
                            VStack(spacing: 8) {
                                ProgressSlider(
                                    trackProgress: $viewModel.trackProgress,
                                    isTracking: $viewModel.isProgressTracking,
                                    initialValue: $viewModel.initialProgressValue,
                                    shouldAnimatePadding: $viewModel.shouldAnimateProgressPadding
                                )
                                    .frame(height: 8)
                                    .accentColor(viewModel.primaryControlsColor)
                                    .animation(
                                        .linear(duration: 1),
                                        value: viewModel.shouldAnimateProgressSlider
                                    )
                                
                                HStack {
                                    Text(viewModel.trackProgress.value.time)
                                        .foregroundColor(viewModel.secondaryControlsColor)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.trackProgress.remaining.time)
                                        .multilineTextAlignment(.trailing)
                                        .foregroundColor(viewModel.secondaryControlsColor)
                                }
                            }
                        }
                        .transition(
                            .move(edge: .top)
                            .combined(with: .opacity)
                        )
//                    }
                    
                // MARK: - Playlist Layout
                    
                case .playlist:
                    
                    HStack(alignment: .center, spacing: 16) {
                        cachedArtworkImage(
                            viewModel.currentPlayerContent?.name,
                            isMainArtwork: true
                        )
                            .resizable()
                            .cornerRadius(4)
                            .frame(
                                width: viewModel.playlistArtworkWidth,
                                height: viewModel.playlistArtworkWidth
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.currentPlayerContent?.title ?? viewModel.placeholderTitle)
                                .foregroundColor(viewModel.primaryControlsColor)
                                .font(.system(size: 18, weight: .semibold))
                            
                            if let artist = viewModel.currentPlayerContent?.artist {
                                Text(artist)
                                    .foregroundColor(viewModel.secondaryControlsColor)
                                    .font(.system(size: 16, weight: .regular))
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.bottom, -32)
                    .transition(
                        .scale(
                            scale: viewModel.artworkScale,
                            anchor: .topLeading
                        )
                        .combined(with: .opacity)
                        .combined(with: .offset(
                            x: viewModel.playerArtworkPadding / 2 + viewModel.playlistArtworkWidth / 4,
                            y: viewModel.playerArtworkPadding / 2 + viewModel.playlistArtworkWidth / 4
                        ))
                    )
                    
                    VStack(spacing: 12) {
                        HStack(alignment: .center, spacing: 24) {
                            Text("Playing Next")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(viewModel.primaryControlsColor)
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button {
                                    Task {
                                        do {
                                            try await viewModel.shuffle()
                                        } catch {
                                            debugPrint(error)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "shuffle")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(viewModel.secondaryControlsColor)
                                }
                            }

                        }
                        
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(
                                    viewModel.queuedPlayerContent
                                ) {
                                    track in
                                    
                                    Button {
                                        guard
                                            let sessionTrackID = track.sessionTrackID
                                        else {
                                            return
                                        }
                                        
                                        Task {
                                            try await viewModel.playTrack(
                                                sessionTrackID: sessionTrackID
                                            )
                                        }
                                    } label: {
                                        HStack(alignment: .center, spacing: 14) {
                                            cachedArtworkImage(track.name)
                                                .cornerRadius(4)
                                                .frame(
                                                    width: viewModel.playlistQueueArtworkWidth,
                                                    height: viewModel.playlistQueueArtworkWidth
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(track.title ?? viewModel.defaultTitle)
                                                    .foregroundColor(viewModel.primaryControlsColor)
                                                    .font(.system(size: 16, weight: .medium))
                                                
                                                if let artist = track.artist {
                                                    Text(artist)
                                                        .foregroundColor(viewModel.secondaryControlsColor)
                                                        .font(.system(size: 14, weight: .regular))
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            Button {
                                                guard
                                                    let sessionTrackID = track.sessionTrackID
                                                else {
                                                    return
                                                }
                                                
                                                Task {
                                                    try await viewModel.delayPlayTrack(
                                                        sessionTrackID: sessionTrackID
                                                    )
                                                }
                                            } label: {
                                                Image(systemName: "text.insert")
                                                    .foregroundColor(viewModel.primaryControlsColor)
                                            }
                                        }
                                    }

                                }
                            }
                            .padding(.top, 8)
                            .padding(.bottom, 24)
                        }
                    }
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(white: 0, opacity: 1))
                            
                            LinearGradient(
                                colors: [
                                    Color(white: 0, opacity: 1),
                                    Color(white: 0, opacity: 0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 24)
                        }
                    )
                    .padding(.bottom, -64)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
                    
                // MARK: - Library Layout
                    
                case .library:
                    VStack(spacing: 16) {
                        HStack {
                            Menu {
                                Button {
                                    withAnimation {
                                        viewModel.libraryState = .ownPlaylists
                                    }
                                } label: {
                                    Label("My Playlists", systemImage: "text.badge.star")
                                }

                                
                                Button {
                                    withAnimation {
                                        viewModel.libraryState = .playlists
                                    }
                                } label: {
                                    Label("Playlists", systemImage: "music.note.list")
                                }
                                
                                Button {
                                    withAnimation {
                                        viewModel.libraryState = .tracks
                                    }
                                } label: {
                                    Label("Tracks", systemImage: "music.note")
                                }
                            } label: {
                                ZStack(alignment: .leading) {
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("My Playlists")
                                            .font(.system(
                                                size: 32,
                                                weight: .bold
                                            ))
                                            .foregroundColor(viewModel.primaryControlsColor)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(
                                                size: 16,
                                                weight: .medium
                                            ))
                                            .padding(.top, 4)
                                            .foregroundColor(viewModel.primaryControlsColor)
                                    }
                                    .opacity(viewModel.libraryState == .ownPlaylists ? 1 : 0)
                                    
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("Playlists")
                                            .font(.system(
                                                size: 32,
                                                weight: .bold
                                            ))
                                            .foregroundColor(viewModel.primaryControlsColor)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(
                                                size: 16,
                                                weight: .medium
                                            ))
                                            .padding(.top, 4)
                                            .foregroundColor(viewModel.primaryControlsColor)
                                    }
                                    .opacity(viewModel.libraryState == .playlists ? 1 : 0)
                                    
                                    HStack(alignment: .center, spacing: 8) {
                                        Text("Tracks")
                                            .font(.system(
                                                size: 32,
                                                weight: .bold
                                            ))
                                            .foregroundColor(viewModel.primaryControlsColor)
                                        
                                        Image(systemName: "chevron.down")
                                            .font(.system(
                                                size: 16,
                                                weight: .medium
                                            ))
                                            .padding(.top, 4)
                                            .foregroundColor(viewModel.primaryControlsColor)
                                    }
                                    .opacity(viewModel.libraryState == .tracks ? 1 : 0)
                                }
                            }
                            
                            Spacer()
                            
                            switch viewModel.libraryState {
                            case .ownPlaylists, .playlists:
                                Button {
                                    addPlaylistViewModel.isShowing = true
                                } label: {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 24, weight: .medium))
                                        .foregroundColor(.pink)
                                }
                                .transition(.opacity)
                                
                            case .tracks:
                                EmptyView()
                            }
                        }
                        
                        ScrollView(showsIndicators: false) {
                            switch viewModel.libraryState {
                            case .ownPlaylists:
                                VStack(alignment: .leading, spacing: 18) {
                                    ForEach(viewModel.ownPlaylists) { playlist in
                                        Button {
                                            guard
                                                let playlistID = playlist.id
                                            else {
                                                return
                                            }
                                            
                                            playlistViewModel.selectedPlaylist = playlist
                                            
                                            viewModel.subscribeToPlaylist(playlistID: playlistID)
                                        } label: {
                                            HStack(alignment: .center, spacing: 16) {
                                                Image(uiImage: playlist.cover)
                                                    .resizable()
                                                    .cornerRadius(4)
                                                    .frame(width: 60, height: 60)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(playlist.name)
                                                        .foregroundColor(viewModel.primaryControlsColor)
                                                        .font(.system(size: 18, weight: .medium))
                                                    
                                                    Text(playlist.accessType.description)
                                                        .foregroundColor(viewModel.secondaryControlsColor)
                                                        .font(.system(size: 16, weight: .regular))
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                                .transition(.opacity)
                                
                            case .playlists:
                                VStack(alignment: .leading, spacing: 18) {
                                    ForEach(viewModel.playlists) { playlist in
                                        Button {
                                            guard
                                                let playlistID = playlist.id
                                            else {
                                                return
                                            }
                                            
                                            playlistViewModel.selectedPlaylist = playlist
                                            
                                            viewModel.subscribeToPlaylist(playlistID: playlistID)
                                        } label: {
                                            HStack(alignment: .center, spacing: 16) {
                                                Image(uiImage: playlist.cover)
                                                    .resizable()
                                                    .cornerRadius(4)
                                                    .frame(width: 60, height: 60)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(playlist.name)
                                                        .foregroundColor(viewModel.primaryControlsColor)
                                                        .font(.system(size: 18, weight: .medium))
                                                    
                                                    if let user = viewModel.user(byID: playlist.author) {
                                                        Text("@\(user.username)")
                                                            .foregroundColor(viewModel.secondaryControlsColor)
                                                            .font(.system(size: 16, weight: .regular))
                                                    } else if viewModel.ownPlaylists
                                                        .contains(where: { $0.id == playlist.id }) {
                                                        Text("Yours")
                                                            .foregroundColor(viewModel.secondaryControlsColor)
                                                            .font(.system(size: 16, weight: .regular))
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                                .transition(.opacity)
                                
                            case .tracks:
                                VStack(alignment: .leading, spacing: 12) {
                                    ForEach(
                                        viewModel.tracksPlayerContent
                                    ) { track in
                                        Button {
                                            Task {
                                                guard
                                                    let sessionTrackID = track.sessionTrackID
                                                else {
                                                    return
                                                }
                                                
                                                try await viewModel.playTrack(sessionTrackID: sessionTrackID)
                                                
                                                viewModel.interfaceState = .player
                                            }
                                        } label: {
                                            HStack(alignment: .center, spacing: 16) {
                                                cachedArtworkImage(track.name)
                                                    .resizable()
                                                    .cornerRadius(4)
                                                    .frame(width: 60, height: 60)
                                                
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(track.title ?? viewModel.defaultTitle)
                                                        .foregroundColor(viewModel.primaryControlsColor)
                                                        .font(.system(size: 18, weight: .medium))
                                                    
                                                    if let artist = track.artist {
                                                        Text(artist)
                                                            .foregroundColor(viewModel.secondaryControlsColor)
                                                            .font(.system(size: 16, weight: .regular))
                                                    }
                                                }
                                                
                                                Spacer()
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                }
                                .padding(.top, 8)
                                .padding(.bottom, 24)
                                .transition(.opacity)
                            }
                        }
                    }
                    .mask(
                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(Color(white: 0, opacity: 1))
                            
                            LinearGradient(
                                colors: [
                                    Color(white: 0, opacity: 1),
                                    Color(white: 0, opacity: 0),
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 24)
                        }
                    )
                    .padding(.bottom, -64)
                    .transition(
                        .move(edge: .bottom)
                        .combined(with: .opacity)
                    )
                }
                
                // MARK: - Control Bar
                
                HStack(alignment: .center, spacing: 16) {
                    
                    Button {
                        Task {
                            try await viewModel.backward()
                        }
                    } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(viewModel.primaryControlsColor)
                    }
                    .buttonStyle(SubControlButtonStyle())
                    
                    Button {
                        Task {
                            do {
                                switch viewModel.playerState {
                                case .playing:
                                    try await viewModel.pause()

                                case .paused:
                                    try await viewModel.resume()
                                }
                                
                                await MainActor.run {
                                    viewModel.animatingPlayerState.toggle()
                                    
                                    viewModel.playerState.toggle()
                                }
                            } catch {
                                print(error)
                            }
                        }
                    } label: {
                        switch viewModel.playerState {
                        case .playing:
                            Image(systemName: "pause.fill")
                                .font(.system(size: 48))

                        case .paused:
                            Image(systemName: "play.fill")
                                .font(.system(size: 48))
                        }
                    }
                    .frame(width: 80, height: 80)
                    .buttonStyle(ControlButtonStyle())
                    .transition(.opacity)
                    .animation(
                        .linear(duration: 0.34),
                        value: viewModel.animatingPlayerState
                    )
                    
                    Button {
                        Task {
                            try await viewModel.forward()
                        }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(viewModel.primaryControlsColor)
                    }
                    .frame(width: 80, height: 80)
                    .buttonStyle(SubControlButtonStyle())
                }
                
                // MARK: - Bottom Bar
                
                HStack(alignment: .center, spacing: 76) {
                    Button {
                        switch viewModel.interfaceState {
                        case .library:
                            viewModel.artworkTransitionAnchor = .center
                            
                        case .player, .playlist:
                            viewModel.artworkTransitionAnchor = .center
                        }
                        
                        withAnimation {
                            viewModel.interfaceState = {
                                switch viewModel.interfaceState {
                                case .library:
                                    return .player
                                    
                                case .player, .playlist:
                                    return .library
                                }
                            }()
                        }
                    } label: {
                        switch viewModel.interfaceState {
                        case .player, .playlist:
                            Image(systemName: "music.note.list")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(viewModel.secondaryControlsColor)
                            
                        case .library:
                            Image(systemName: "music.note.list")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(viewModel.secondaryControlsColor)
                                .background(
                                    viewModel.secondaryControlsColor,
                                    in: RoundedRectangle(cornerRadius: 2)
                                        .inset(by: -5)
                                )
                                .mask(alignment: .center) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .inset(by: -5)
                                        .overlay(alignment: .center) {
                                            Image(systemName: "music.note.list")
                                                .font(.system(size: 24, weight: .medium))
                                                .blendMode(.destinationOut)
                                        }
                                }
                        }
                    }
                    .frame(width: 40, height: 38)
                    
                    Button {
                        viewModel.showingSignOutConfirmation = true
                    } label: {
                        Image(systemName: "person.crop.circle.badge.xmark")
                            .font(.system(size: 24))
                            .foregroundColor(viewModel.secondaryControlsColor)
                    }
                    .frame(width: 40, height: 38)
                    
                    Button {
                        switch viewModel.interfaceState {
                        case .player, .library:
                            viewModel.artworkTransitionAnchor = .topLeading
                            
                        case .playlist:
                            viewModel.artworkTransitionAnchor = .topLeading
                        }
                        
                        withAnimation {
                            viewModel.interfaceState = {
                                switch viewModel.interfaceState {
                                case .player, .library:
                                    return .playlist
                                    
                                case .playlist:
                                    return .player
                                }
                            }()
                        }
                    } label: {
                        switch viewModel.interfaceState {
                        case .player, .library:
                            Image(systemName: "list.bullet")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(viewModel.secondaryControlsColor)
                            
                        case .playlist:
                            Image(systemName: "list.bullet")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(viewModel.secondaryControlsColor)
                                .background(
                                    viewModel.secondaryControlsColor,
                                    in: RoundedRectangle(cornerRadius: 2)
                                        .inset(by: -5)
                                )
                                .mask(alignment: .center) {
                                    RoundedRectangle(cornerRadius: 2)
                                        .inset(by: -5)
                                        .overlay(alignment: .center) {
                                            Image(systemName: "list.bullet")
                                                .font(.system(size: 24, weight: .medium))
                                                .blendMode(.destinationOut)
                                        }
                                }
                            
                        }
                    }
                    .frame(width: 40, height: 38)
                }
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 32)
        }
        .preferredColorScheme(.dark)
        .sheet(
            isPresented: $addPlaylistViewModel.isShowing,
            content: {
                AddPlaylistView(
                    api: api,
                    focusedField: $focusedField
                )
                    .environmentObject(viewModel)
                    .environmentObject(addPlaylistViewModel)
            }
        )
        .sheet(
            isPresented: $playlistViewModel.isShowing,
            content: {
                PlaylistView(
                    api: api,
                    focusedField: $focusedField
                )
                .environmentObject(viewModel)
                .environmentObject(playlistViewModel)
            }
        )
        .ignoresSafeArea(.keyboard)
        .confirmationDialog(
            "Sign Out?",
            isPresented: $viewModel.showingSignOutConfirmation,
            titleVisibility: .visible
        ) {
            
            // MARK: - Sign Out Confirmation Dialog
            
            Button(role: .destructive) {
                Task {
                    await MainActor.run {
                        viewModel.showingSignOutConfirmation = false
                    }
                    
                    try await viewModel.signOut()
                    
                    await MainActor.run {
                        authViewModel.isShowing = true
                    }
                    
                    await MainActor.run {
                        viewModel.signInToastType = .complete(Color.pink)
                        viewModel.signInToastTitle = "Signed Out"
                        viewModel.signInToastSubtitle = "Bye"
                        viewModel.isSignInToastShowing = true
                    }
                }
            } label: {
                Text("Yes")
            }

        }
        .sheet(
            isPresented: $authViewModel.isShowing,
            content: {
                AuthView(api: api, focusedField: $focusedField)
                    .environmentObject(viewModel)
                    .environmentObject(authViewModel)
            }
        )
        .toast(
            isPresenting: $viewModel.isToastShowing,
            duration: 3,
            tapToDismiss: true,
            offsetY: 0,
            alert: {
                AlertToast(
                    displayMode: .hud,
                    type: viewModel.toastType,
                    title: viewModel.toastTitle,
                    subTitle: viewModel.toastSubtitle,
                    style: nil
                )
            }
        )
        .onAppear {
            
            // MARK: - On Appear
            
            viewModel.api = api
            
            playlistViewModel.viewModel = viewModel
            
            if viewModel.isAuthorized {
                viewModel.updateData()
            } else {
                authViewModel.isShowing = !viewModel.isAuthorized
            }
        }
    }
}
