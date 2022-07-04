//
//  PlaylistMessage.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct PlaylistMessage: Codable {
    public let event: PlaylistEventsList
    
    public enum Payload: Codable {
        case renamePlaylist(playlistId: Int, playlistName: String)
        
        case addPlaylist(playlistName: String, type: Playlist.`Type`)
        
        case removePlaylist(playlistId: Int, playlistName: String?)
        
        case addTrack(trackId: Int)
        
        case removeTrack(trackId: Int)
        
        case playlistsChanged(playlist: Playlist?, playlists: [Playlist]?)
    }
    
    public let payload: Payload
}
