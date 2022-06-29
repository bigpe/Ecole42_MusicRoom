//
//  ContentView+ViewModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import SwiftUI

extension ContentView {
    
    @MainActor
    class ViewModel: ObservableObject {
        enum InterfaceState {
            case player
            
            case playlist
        }
        
        enum PlayerState {
            case playing, paused
            
            mutating func toggle() {
                self = {
                    switch self {
                    case .playing:
                        return .paused
                        
                    case .paused:
                        return .playing
                    }
                }()
            }
        }
        
        enum ShuffleState {
            case on, off
            
            mutating func toggle() {
                self = {
                    switch self {
                    case .on:
                        return .off
                        
                    case .off:
                        return .on
                    }
                }()
            }
        }
        
        let primaryControlsColor = Color.primary
        
        let secondaryControlsColor = Color.primary.opacity(0.55)
        
        @Published
        var interfaceState = InterfaceState.player
        
        @Published
        var playerState = PlayerState.paused
        
        @Published
        var shuffleState = ShuffleState.off
        
        @Published
        var track: Track?
        
        @Published
        var playlist: Playlist?
        
        var tracks = [Track]()
        
        var playlistTracks: [Track] {
            return [
                Track(id: 1, name: "Jakarta — One Desire"),
                Track(id: 2, name: "Don Diablo — Silence"),
                Track(id: 3, name: "Adele — Skyfall"),
            ]
            
            (playlist?.tracks ?? [])
                .map { playlistTrack in
                    tracks.first(where: { $0.id == playlistTrack.id }) ?? Track(name: "Unknown")
                }
        }
    }
}
