//
//  PlaylistsMessage.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 12.07.2022.
//

import Foundation

public struct PlaylistsMessage: Codable {
    public let event: PlaylistsEventsList
    
    public enum Payload: Codable {
        
        // MARK: - Requests
        
        case changePlaylist(playlist_id: Int, playlist_name: String, playlist_access_type: Playlist.AccessType)
        
        case addPlaylist(playlist_name: String, access_type: Playlist.AccessType)
        
        case removePlaylist(playlist_id: Int, playlist_name: String?, playlist_access_type: Playlist.AccessType?)
        
        // MARK: - Responses
        
        case playlistsChanged(playlists: [Playlist])
    }
    
    public let payload: Payload
}
