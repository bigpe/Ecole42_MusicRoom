//
//  PlaylistsEventsList.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 12.07.2022.
//

import Foundation

public enum PlaylistsEventsList: String, Codable {
    
    // MARK: - Responses
    
    case playlistsChanged = "playlists.changed"
    
    // MARK: - Requests
    
    case changePlaylist = "change.playlist"
    
    case addPlaylist = "add.playlist"
    
    case removePlaylist = "remove.playlist"
}
