//
//  SessionTrack.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct SessionTrack: Codable {
    public let id: Int?
    
    public enum State: String, Codable {
        case stopped, playing, paused
    }
    
    public let state: State?
    
    public let progress: Decimal?
    
    public let track: Int
    
    public init(
        id: Int? = nil,
        state: SessionTrack.State? = nil,
        progress: Decimal? = nil,
        track: Int
    ) {
        self.id = id
        self.state = state
        self.progress = progress
        self.track = track
    }
}
