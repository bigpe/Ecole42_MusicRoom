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
        
        @Published
        var isShowing = false
        
        @Published
        var nameText = ""
        
        @Published
        var accessType = Playlist.AccessType.private
        
        @Published
        var isLoading = false
        
        @Published
        var isShowingAddMusic = false
        
        @Published
        var selectedTracks = Set<Int?>()
        
        var cancellable: AnyCancellable?
        
        func reset() {
            nameText = ""
            accessType = .private
            isLoading = false
            selectedTracks = []
        }
    }
}
