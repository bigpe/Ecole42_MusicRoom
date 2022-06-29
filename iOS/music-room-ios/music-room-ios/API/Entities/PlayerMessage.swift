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
        case createSession(playlistId: Int, shuffle: Bool)
        
        case removeSession
        
        case playTrack(playerSessionId: Int, trackId: Int)
        
        case playNextTrack(playerSessionId: Int, trackId: Int?)
        
        case playPreviousTrack(playerSessionId: Int, trackId: Int?)
        
        case shuffle(playerSessionId: Int, trackId: Int?)
        
        case pauseTrack(playerSessionId: Int, trackId: Int?)
        
        case resumeTrack(playerSessionId: Int, trackId: Int?)
        
        case stopTrack(playerSessionId: Int, trackId: Int?)
        
        case syncTrack(playerSessionId: Int, progress: Int)
        
        case sessionChanged(playerSession: PlayerSession)
        
        case session(playerSession: PlayerSession)
    }
    
    public let payload: Payload
}
