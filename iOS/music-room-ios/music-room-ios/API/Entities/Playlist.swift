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
    
    public enum `Type`: String, Codable {
        case `public`, `private`
    }
    
    public let type: `Type`?
    
    public enum AccessType: String, Codable {
        case `default`, custom
    }
    
    public let accessType: AccessType?
    
    public let author: Int
    
    public init(
        id: Int? = nil,
        tracks: [PlaylistTrack],
        name: String,
        type: `Type`? = nil,
        accessType: AccessType? = nil,
        author: Int
    ) {
        self.id = id
        self.tracks = tracks
        self.name = name
        self.type = type
        self.accessType = accessType
        self.author = author
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case tracks
        case name
        case type
        case accessType = "access_type"
        case author
    }
}
