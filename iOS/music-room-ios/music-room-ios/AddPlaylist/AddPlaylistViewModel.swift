//
//  ContentView+AddPlaylistViewModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 10.07.2022.
//

import SwiftUI
import Combine

@MainActor
class AddPlaylistViewModel: ObservableObject {
    
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
    var selectedPlayerContent = [ViewModel.PlayerContent]()
    
    // MARK: - Add Music
    
    @Published
    var isShowingAddMusic = false
    
    @Published
    var selectedAddMusicTracks = [Int?]() // FIXME: Publishing changes from within view updates is not allowed, this will cause undefined behavior.
    
    // MARK: -
    
    var cancellable: AnyCancellable?
    
    func reset() {
        nameText = ""
        accessType = .private
        isLoading = false
        selectedPlayerContent = []
    }
}
