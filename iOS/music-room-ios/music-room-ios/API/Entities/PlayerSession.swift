//
//  PlayerSession.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct PlayerSession: Codable, Identifiable {
    public let id: Int?
    
    public let trackQueue: [SessionTrack]
    
    public let mode: String?
    
    public let playlist: Int
    
    public let author: Int
    
    public init(
        id: Int? = nil,
        trackQueue: [SessionTrack],
        mode: String? = nil,
        playlist: Int,
        author: Int
    ) {
        self.id = id
        self.trackQueue = trackQueue
        self.mode = mode
        self.playlist = playlist
        self.author = author
    }
}
