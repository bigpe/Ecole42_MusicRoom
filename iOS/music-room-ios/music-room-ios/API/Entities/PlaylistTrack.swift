//
//  PlaylistTrack.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct PlaylistTrack: Codable, Identifiable {
    public let id: Int?
    
    public let order: Int?
    
    public let track: Int
    
    public let playlist: Int
    
    public init(
        id: Int? = nil,
        order: Int? = nil,
        track: Int,
        playlist: Int
    ) {
        self.id = id
        self.order = order
        self.track = track
        self.playlist = playlist
    }
}
