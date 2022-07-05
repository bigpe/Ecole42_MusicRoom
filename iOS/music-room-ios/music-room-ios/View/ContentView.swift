//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI

struct ContentView: View {
    
    private let api = API()
    
    @StateObject
    private var viewModel = ViewModel()
    
    @StateObject
    private var authSheet = AuthSheet()
    
    @FocusState
    var focusedField: AuthSheet.Field?
    
    @StateObject
    private var musicKit = MusicKit()
    
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
    
    // MARK: - Album Cover
    
    let albumCover = generateImage(
        CGSize(width: 1000, height: 1000),
        rotatedContext: { size, context in
            
            context.clear(CGRect(origin: CGPoint(), size: size))
            
            let musicNoteIcon = UIImage(systemName: "music.note.list")?
                .withConfiguration(UIImage.SymbolConfiguration(
                    pointSize: 1000 * 0.375,
                    weight: .medium
                ))
            ?? UIImage()
            
            drawIcon(
                context: context,
                size: size,
                icon: musicNoteIcon,
                iconSize: musicNoteIcon.size,
                iconColor: UIColor(displayP3Red: 0.462, green: 0.458, blue: 0.474, alpha: 1),
                colors: [
                    UIColor(displayP3Red: 0.33, green: 0.325, blue: 0.349, alpha: 1),
                    UIColor(displayP3Red: 0.33, green: 0.325, blue: 0.349, alpha: 1),
                ]
            )
        }
    )?
        .withRenderingMode(.alwaysOriginal) ?? UIImage()
    
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
                    GeometryReader { geometry in
                        cachedArtworkImage(
                            viewModel.currentTrack?.name,
                            geometry: geometry,
                            isMainArtwork: true
                        )
                            .resizable()
                            .aspectRatio(1, contentMode: .fit)
                            .cornerRadius(8)
                            .shadow(color: Color(white: 0, opacity: 0.3), radius: 4, x: 0, y: 4)
                    }
                    .scaleEffect(
                        { () -> CGFloat in
                            switch viewModel.playerState {
                            case .paused:
                                return 0.8
                                
                            case .playing:
                                return 1
                            }
                        }(),
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
                    
                    VStack(alignment: .leading, spacing: 48) {
                        Text(viewModel.currentTrack?.name ?? viewModel.placeholderTitle)
                            .foregroundColor(viewModel.primaryControlsColor)
                            .font(.headline)
                            .dynamicTypeSize(.xLarge)
                        
                        VStack(spacing: 8) {
                            ProgressView(
                                value: ((viewModel.currentSessionTrack?.progress ?? 0) as NSDecimalNumber).doubleValue,
                                total: ((viewModel.currentTrack?.duration ?? 0) as NSDecimalNumber).doubleValue
                            )
                                .tint(viewModel.secondaryControlsColor)
                            
                            HStack {
                                Text(viewModel.currentSessionTrack?.progress?.time ?? "--:--")
                                    .foregroundColor(viewModel.secondaryControlsColor)
                                
                                Spacer()
                                
                                Text(viewModel.currentTrack?.duration.time ?? "--:--")
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
                    
                    HStack(alignment: .center, spacing: 16) {
                        cachedArtworkImage(viewModel.currentTrack?.name, isMainArtwork: true)
                            .resizable()
                            .cornerRadius(4)
                            .frame(
                                width: viewModel.playlistArtworkWidth,
                                height: viewModel.playlistArtworkWidth
                            )
                        
                        Text(viewModel.currentTrack?.name ?? viewModel.placeholderTitle)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(viewModel.primaryControlsColor)
                        
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
                                    viewModel.shuffleState.toggle()
                                } label: {
                                    switch viewModel.shuffleState {
                                    case .off:
                                        Image(systemName: "shuffle.circle")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(viewModel.secondaryControlsColor)
                                        
                                    case .on:
                                        Image(systemName: "shuffle.circle.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(viewModel.primaryControlsColor)
                                    }
                                }
                                
                                Button {
                                    viewModel.repeatState.toggle()
                                } label: {
                                    switch viewModel.repeatState {
                                    case .off:
                                        Image(systemName: "repeat.circle")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(viewModel.secondaryControlsColor)
                                        
                                    case .on:
                                        Image(systemName: "repeat.circle.fill")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(viewModel.primaryControlsColor)
                                    }
                                }
                            }

                        }
                        
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.queuedTracks) { track in
                                    HStack(alignment: .center, spacing: 14) {
                                        cachedArtworkImage(track.name)
                                            .cornerRadius(4)
                                            .frame(
                                                width: viewModel.playlistQueueArtworkWidth,
                                                height: viewModel.playlistQueueArtworkWidth
                                            )
                                        
                                        Text(track.name)
                                            .font(.system(size: 16, weight: .medium))
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
                                    // FIXME: Add
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
                                            Task {
                                                guard
                                                    let playlistID = playlist.id
                                                else {
                                                    return
                                                }
                                                
                                                try await viewModel.createSession(
                                                    playlistID: playlistID
                                                )
                                                
                                                viewModel.interfaceState = .player
                                            }
                                        } label: {
                                            HStack(alignment: .center, spacing: 16) {
                                                Image(uiImage: albumCover)
                                                    .resizable()
                                                    .cornerRadius(4)
                                                    .frame(width: 60, height: 60)
                                                
                                                Text(playlist.name)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(viewModel.primaryControlsColor)
                                                    .padding(.vertical, 12)
                                                
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
                                            Task {
                                                guard
                                                    let playlistID = playlist.id
                                                else {
                                                    return
                                                }
                                                
                                                do {
                                                    try await viewModel.createSession(
                                                        playlistID: playlistID
                                                    )
                                                } catch {
                                                    debugPrint(error)
                                                }
                                                
                                                viewModel.interfaceState = .player
                                            }
                                        } label: {
                                            HStack(alignment: .center, spacing: 16) {
                                                Image(uiImage: albumCover)
                                                    .resizable()
                                                    .cornerRadius(4)
                                                    .frame(width: 60, height: 60)
                                                
                                                Text(playlist.name)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(viewModel.primaryControlsColor)
                                                    .padding(.vertical, 12)
                                                
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
                                    ForEach(viewModel.tracks) { track in
                                        Button {
                                            Task {
                                                guard
                                                    let trackID = track.id
                                                else {
                                                    return
                                                }
                                                
                                                try await viewModel.playTrack(trackID: trackID)
                                                
                                                viewModel.interfaceState = .player
                                            }
                                        } label: {
                                            HStack(alignment: .center, spacing: 16) {
                                                cachedArtworkImage(track.name)
                                                    .resizable()
                                                    .cornerRadius(4)
                                                    .frame(width: 60, height: 60)
                                                
                                                Text(track.name)
                                                    .font(.system(size: 18, weight: .medium))
                                                    .foregroundColor(viewModel.primaryControlsColor)
                                                    .padding(.vertical, 12)
                                                
                                                Spacer()
                                            }
                                        }
                                    }
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
                            try await viewModel.backward()
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
                        authSheet.isShowing = true
                    }
                }
            } label: {
                Text("Yes")
            }

        }
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
                        let username = authSheet.usernameText
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        let password = authSheet.passwordText
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        guard
                            !authSheet.isLoading,
                            !username.isEmpty,
                            password.count >= 8
                        else {
                            return // FIXME: Error Message
                        }
                        
                        Task {
                            await MainActor.run {
                                authSheet.isLoading = true
                            }
                            
                            do {
                                try await viewModel.auth(username, password)
                                
                                await MainActor.run {
                                    authSheet.isLoading = false
                                    authSheet.isShowing = false
                                }
                            } catch {
                                debugPrint(error)
                                
                                await MainActor.run {
                                    authSheet.isLoading = false
                                }
                                
                                // FIXME: Error Message
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
            
            // MARK: - On Appear
            
            viewModel.api = api
            
            if viewModel.isAuthorized {
                viewModel.updateData()
            } else {
                authSheet.isShowing = !viewModel.isAuthorized
            }
        }
    }
}
