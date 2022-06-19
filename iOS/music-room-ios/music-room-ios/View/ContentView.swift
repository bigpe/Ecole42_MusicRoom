//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    private static let testUserID = "8"
    
    private let playerWebSocket = try? PlayerWebSocket(userID: testUserID)
    
    private let playlistWebSocket = try? PlaylistWebSocket(userID: testUserID)
    
    @State
    private var artworkURL: URL?
    
    @State
    private var title = "Not Playing"
    
    @State
    private var isPlaying = false
    
    @State
    private var isShuffle = false
    
    @State
    private var isPlaylistShowing = false
    
    /// Makes a new search request to MusicKit when the current search term changes.
    private func requestUpdatedSearchResults(for searchTerm: String) {
        Task {
            if searchTerm.isEmpty {
                await reset()
            } else {
                do {
                    if MusicAuthorization.currentStatus == .notDetermined {
                        _ = await MusicAuthorization.request()
                    }
                    
                    var searchRequest = MusicCatalogSearchRequest(
                        term: searchTerm,
                        types: [Song.self]
                    )
                    
                    searchRequest.limit = 5
                    
                    let searchResponse = try await searchRequest.response()
                    
                    guard
                        let song = searchResponse.songs.first
                    else {
                        return
                    }
                    
                    await apply(song)
                } catch let error {
                    print("Search request failed with error: \(error).")
                    
                    await reset()
                }
            }
        }
    }
    
    /// Apply Song Metadata
    @MainActor
    private func apply(_ song: Song) {
        artworkURL = song.artwork?.url(width: 1000, height: 1000)
    }
    
    @MainActor
    private func reset() {
        artworkURL = nil
    }
    
    var body: some View {
        let artworkView = AsyncImage(url: artworkURL) { phase in
            switch phase {
            case .empty:
                EmptyView()
                
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(8, antialiased: true)
                
            case .failure:
                EmptyView()
                
            @unknown default:
                EmptyView()
            }
        }
        
        LazyVStack(alignment: .center, spacing: 64) {
            
            if isPlaylistShowing {
                RoundedRectangle(cornerRadius: 4, style: .circular)
                    .size(width: 64, height: 64)
                    .foregroundColor(.gray)
                    .overlay {
                        artworkView
                    }
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Jakarta — One Desire")
                                .padding(.vertical, 12)
                            
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image(systemName: "text.insert")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack {
                            Text("Jakarta — One Desire")
                                .padding(.vertical, 12)
                            
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image(systemName: "text.insert")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack {
                            Text("Jakarta — One Desire")
                                .padding(.vertical, 12)
                            
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image(systemName: "text.insert")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        HStack {
                            Text("Jakarta — One Desire")
                                .padding(.vertical, 12)
                            
                            Spacer()
                            
                            Button {
                                
                            } label: {
                                Image(systemName: "text.insert")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }
                
                Spacer()
            } else {
                RoundedRectangle(cornerRadius: 8, style: .circular)
                    .aspectRatio(1, contentMode: .fit)
                    .foregroundColor(.gray)
                    .overlay {
                        artworkView
                    }
                
                LazyVStack(alignment: .leading, spacing: 48) {
                    Text(title)
                        .font(.headline)
                        .dynamicTypeSize(.xLarge)
                    
                    LazyVStack(spacing: 8) {
                        ProgressView(value: 0.5, total: 1)
                            .tint(.gray)
                        
                        HStack {
                            Text("--:--")
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Text("--:--")
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
            
            LazyHStack(alignment: .center, spacing: 64) {
                Button {
                    Task {
                        do {
                            try await playerWebSocket?.playPreviousTrack()
                        } catch {
                            debugPrint(error)
                        }
                    }
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
                
                Button {
                    Task {
                        do {
                            if !isPlaying {
                                try await playerWebSocket?.playTrack()
                            } else {
                                try await playerWebSocket?.pauseTrack()
                            }
                            
                            
                            isPlaying.toggle()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.black)
                }
                
                Button {
                    Task {
                        do {
                            try await playerWebSocket?.playNextTrack()
                        } catch {
                            debugPrint(error)
                        }
                    }
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
            }
            
            LazyHStack(alignment: .center, spacing: 76) {
                Button {
                    Task {
                        do {
                            try await playerWebSocket?.shuffle()
                        } catch {
                            debugPrint(error)
                        }
                    }
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 20))
                        .foregroundColor(.gray)
                }
                
                Button {
                    print("Settings")
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.gray)
                }
                
                Button {
                    withAnimation(.spring()) {
                        isPlaylistShowing.toggle()
                    }
                } label: {
                    if !isPlaylistShowing {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.gray)
                    } else {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                            .background(.gray, in: RoundedRectangle(cornerRadius: 2).inset(by: -4))
                    }
                }
            }
        }
        .padding(.horizontal, 32)
        .onAppear {
            if let playerWebSocket = playerWebSocket, !playerWebSocket.isSubscribed {
                playerWebSocket
                    .onReceive { event in
                        switch event {
                            
                        case .playTrack:
                            isPlaying = true
                            
                        case .playNextTrack:
                            break
                            
                        case .playPreviousTrack:
                            break
                            
                        case .shuffle:
                            isShuffle.toggle()
                            
                        case .pauseTrack:
                            isPlaying = false
                            
                        case .resumeTrack:
                            isPlaying = true
                            
                        case .stopTrack:
                            isPlaying = false
                            
                        default:
                            break
                        }
                    }
            }
            
            if let playlistWebSocket = playlistWebSocket, !playlistWebSocket.isSubscribed {
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
