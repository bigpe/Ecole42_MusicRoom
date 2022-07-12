//
//  PlaylistEventsList.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public enum PlaylistEventsList: String, Codable {
    
    // MARK: - Responses
    
    case playlistChanged = "playlist.changed"
    
    // MARK: - Requests
    
    case addTrack = "add.track"
    
    case removeTrack = "remove.track"
    
    case inviteToPlaylist = "invite.to.playlist"
    
    case revokeFromPlaylist = "revoke.from.playlist"
}
