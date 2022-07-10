//
//  ContentView+PlaylistSheet.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 10.07.2022.
//

import SwiftUI

extension ContentView {
    @MainActor
    class PlaylistSheet: ObservableObject {
        
        @Published
        var isShowing = false
        
        @Published
        var selectedPlaylist: Playlist? {
            didSet {
                isShowing = selectedPlaylist != nil
            }
        }
    }
}
