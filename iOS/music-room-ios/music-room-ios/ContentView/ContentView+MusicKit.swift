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
        private var inProgressSearchTerms = [String]()
        
        @Published
        var artworkURLs = [String: URL]()
        
        func requestUpdatedSearchResults(for searchTerm: String) {
            Task {
                if !searchTerm.isEmpty, !inProgressSearchTerms.contains(searchTerm) {
                    do {
                        if MusicAuthorization.currentStatus == .notDetermined {
                            _ = await MusicAuthorization.request()
                        }
                        
                        var searchRequest = MusicCatalogSearchRequest(
                            term: searchTerm,
                            types: [Song.self]
                        )
                        
                        searchRequest.limit = 1
                        
                        inProgressSearchTerms.append(searchTerm)
                        
                        let searchResponse = try await searchRequest.response()
                        
                        guard
                            let song = searchResponse.songs.first
                        else {
                            return
                        }
                        
                        add(song, searchTerm: searchTerm)
                    } catch {
                        reset(searchTerm: searchTerm)
                    }
                }
            }
        }
        
        private func add(_ song: Song, searchTerm: String) {
            artworkURLs[searchTerm] = song.artwork?.url(width: 1000, height: 1000)
            
            searchTermDidLoaded(searchTerm)
        }
        
        private func reset(searchTerm: String) {
            artworkURLs[searchTerm] = nil
            
            searchTermDidLoaded(searchTerm)
        }
        
        private func searchTermDidLoaded(_ searchTerm: String) {
            inProgressSearchTerms.removeAll(where: { $0 == searchTerm })
        }
    }
}
