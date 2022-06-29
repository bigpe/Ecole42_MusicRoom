//
//  ContentView+MusicKit.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import SwiftUI
import MusicKit

extension ContentView {
    
    @MainActor
    class MusicKit: ObservableObject {
        
        @Published
        var artworkURL: URL?
        
        @Published
        var artworkPrimaryColor = Color.gray
        
        func requestUpdatedSearchResults(for searchTerm: String) {
            Task {
                if searchTerm.isEmpty {
                    reset()
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
                        
                        apply(song)
                    } catch let error {
                        print("Search request failed with error: \(error).")
                        
                        reset()
                    }
                }
            }
        }
        
        private func apply(_ song: Song) {
            artworkURL = song.artwork?.url(width: 1000, height: 1000)
        }
        
        private func reset() {
            artworkURL = nil
        }
    }
}
