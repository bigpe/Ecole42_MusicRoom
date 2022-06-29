//
//  PlaylistEventsList.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public enum PlaylistEventsList: String, Codable {
    case playlistChanged = "playlist.changed"
    
    case playlistsChanged = "playlists.changed"
    
    case renamePlaylist = "rename.playlist"
    
    case addPlaylist = "add.playlist"
    
    case removePlaylist = "remove.playlist"
    
    case addTrack = "add.track"
    
    case removeTrack = "remove.track"
}
