//
//  ContentView+PlaylistSheet.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 10.07.2022.
//

import SwiftUI
import Combine

extension ContentView {
    @MainActor
    class PlaylistSheet: ObservableObject {
        
        weak var viewModel: ViewModel!
        
        // MARK: - Data
        
        @Published
        var nameText = ""
        
        @Published
        var accessType = Playlist.AccessType.private
        
        @Published
        var tracks = [Track]()
        
        // MARK: - States
        
        @Published
        var isShowing = false
        
        @Published
        var isLoading = false
        
        @Published
        var isEditable = false
        
        @Published
        var isEditing = false
        
        @Published
        var showingCancelConfirmation = false
        
        // MARK: - Add Music
        
        @Published
        var selectedAddMusicTracks = [Int?]()
        
        @Published
        var isShowingAddMusic = false
        
        @Published
        var isLoadingAddMusic = false
        
        // MARK: - Delete
        
        @Published
        var showingDeleteConfirmation = false
        
        // MARK: - Selected Playlist
        
        @Published
        var selectedPlaylist: Playlist? {
            didSet {
                if let selectedPlaylist = selectedPlaylist {
                    if !isEditing {
                        nameText = selectedPlaylist.name
                        accessType = selectedPlaylist.accessType
                    }
                    
                    tracks = selectedPlaylist.tracks
                        .sorted(by: { leftValue, rightValue in
                            guard
                                let leftOrder = leftValue.order,
                                let rightOrder = rightValue.order
                            else {
                                return true
                            }
                            
                            return leftOrder < rightOrder
                        })
                        .compactMap { playlistTrack in
                            viewModel.tracks.first(where: { $0.id == playlistTrack.track })
                        }
                    
                    isShowing = true
                    
                    if let userID = viewModel.playerSession?.author {
                        isEditable = selectedPlaylist.author == userID
                    }
                } else {
                    nameText = ""
                    accessType = .private
                    
                    tracks = []
                    
                    isShowing = false
                    isLoading = false
                    isEditable = false
                    isEditing = false
                    
                    selectedAddMusicTracks = []
                    
                    isShowingAddMusic = false
                    isLoadingAddMusic = false
                    
                    cancellable = nil
                }
            }
        }
        
        var cancellable: AnyCancellable?
    }
}
