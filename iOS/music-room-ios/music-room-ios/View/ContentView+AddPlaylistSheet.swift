//
//  ContentView+AddPlaylistSheet.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 10.07.2022.
//

import SwiftUI
import Combine

extension ContentView {
    @MainActor
    class AddPlaylistSheet: ObservableObject {
        
        // MARK: - States
        
        @Published
        var isShowing = false
        
        @Published
        var isLoading = false
        
        @Published
        var showingCancelConfirmation = false
        
        // MARK: - Data
        
        @Published
        var nameText = ""
        
        @Published
        var accessType = Playlist.AccessType.private
        
        @Published
        var selectedTracks = [Track]()
        
        // MARK: - Add Music
        
        @Published
        var isShowingAddMusic = false
        
        @Published
        var selectedAddMusicTracks = [Int?]()
        
        // MARK: -
        
        var cancellable: AnyCancellable?
        
        func reset() {
            nameText = ""
            accessType = .private
            isLoading = false
            selectedTracks = []
        }
    }
}
