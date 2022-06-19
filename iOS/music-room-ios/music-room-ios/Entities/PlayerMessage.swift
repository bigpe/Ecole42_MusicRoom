//
//  PlayerMessage.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct PlayerMessage: Codable {
    public let event: PlayerEventsList
    
    public enum Payload: Codable {
        case createSession(playlistID: Int, shuffle: Bool)
    }
    
    public let payload: Payload
}
