//
//  Playlist.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct Playlist: Codable, Identifiable {
    public let id: Int?
    
    public let tracks: [PlaylistTrack]
    
    public let name: String
    
    public let type: PlaylistType?
    
    public let author: Int
    
    public init(
        id: Int? = nil,
        tracks: [PlaylistTrack],
        name: String,
        type: PlaylistType? = nil,
        author: Int
    ) {
        self.id = id
        self.tracks = tracks
        self.name = name
        self.type = type
        self.author = author
    }
}
