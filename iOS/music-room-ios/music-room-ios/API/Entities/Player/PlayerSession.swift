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
    
    public enum Mode: String, Codable {
        case normal, `repeat`
    }
    
    public let mode: Mode?
    
    public let playlist: Int?
    
    public let author: Int?
    
    public init(
        id: Int? = nil,
        trackQueue: [SessionTrack],
        mode: Mode? = nil,
        playlist: Int? = nil,
        author: Int? = nil
    ) {
        self.id = id
        self.trackQueue = trackQueue
        self.mode = mode
        self.playlist = playlist
        self.author = author
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case trackQueue = "track_queue"
        case mode
        case playlist
        case author
    }
}
