//
//  ContentView.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 16.06.2022.
//

import SwiftUI
import MusicKit

struct ContentView: View {
    
    @State
    private var artworkURL: URL?
    
    /// Makes a new search request to MusicKit when the current search term changes.
    private func requestUpdatedSearchResults(for searchTerm: String) {
        Task {
            if searchTerm.isEmpty {
//                self.reset()
            } else {
                do {
                    if MusicAuthorization.currentStatus == .notDetermined {
                        _ = await MusicAuthorization.request()
                    }
                    
                    // Issue a catalog search request for albums matching the search term.
                    var searchRequest = MusicCatalogSearchRequest(term: searchTerm, types: [Song.self])
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
        LazyVStack(alignment: .center, spacing: 64) {
            RoundedRectangle(cornerRadius: 8, style: .circular)
                .aspectRatio(1, contentMode: .fit)
                .foregroundColor(.gray)
                .overlay {
                    AsyncImage(url: artworkURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable()
                                .aspectRatio(contentMode: .fit)
                                .cornerRadius(8, antialiased: true)
                        case .failure:
                            EmptyView()
                        @unknown default:
                            EmptyView()
                        }
                    }
                }
            
            LazyVStack(alignment: .leading, spacing: 48) {
                Text("Not Playing")
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
            
            LazyHStack(alignment: .center, spacing: 64) {
                Button {
                    print("Backward")
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
                
                Button {
                    requestUpdatedSearchResults(for: "Skyfall")
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.black)
                }
                
                Button {
                    print("Forward")
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.black)
                }
            }
            
            LazyHStack(alignment: .center, spacing: 76) {
                Button {
                    print("Shuffle")
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
                    print("Playlist")
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 32)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
