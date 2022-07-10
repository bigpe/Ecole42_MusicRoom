//
//  ContentView+AddPlaylistSheet.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 10.07.2022.
//

import SwiftUI

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
        var tracks = [
            Track(id: 1, name: "Gorillaz — DARE", file: "", duration: 321),
            Track(id: 2, name: "Gesaffelstein — Ignio", file: "", duration: 456),
            Track(id: 3, name: "Adele — Skyfall", file: "", duration: 123),
            Track(id: 4, name: "Gorillaz — DARE", file: "", duration: 321),
            Track(id: 5, name: "Gesaffelstein — Ignio", file: "", duration: 456),
            Track(id: 6, name: "Adele — Skyfall", file: "", duration: 123),
            Track(id: 7, name: "Gorillaz — DARE", file: "", duration: 321),
            Track(id: 8, name: "Gesaffelstein — Ignio", file: "", duration: 456),
            Track(id: 9, name: "Adele — Skyfall", file: "", duration: 123),
            Track(id: 10, name: "Gorillaz — DARE", file: "", duration: 321),
            Track(id: 11, name: "Gesaffelstein — Ignio", file: "", duration: 456),
            Track(id: 12, name: "Adele — Skyfall", file: "", duration: 123),
            Track(id: 13, name: "Gorillaz — DARE", file: "", duration: 321),
            Track(id: 14, name: "Gesaffelstein — Ignio", file: "", duration: 456),
            Track(id: 15, name: "Adele — Skyfall", file: "", duration: 123),
            Track(id: 16, name: "Gorillaz — DARE", file: "", duration: 321),
            Track(id: 17, name: "Gesaffelstein — Ignio", file: "", duration: 456),
        ]
        
        @Published
        var isShowingAddTrack = false
        
        @Published
        var selectedTracks = Set<Int?>()
        
        func reset() {
            nameText = ""
            accessType = .private
            isLoading = false
            selectedTracks = []
        }
    }
}
