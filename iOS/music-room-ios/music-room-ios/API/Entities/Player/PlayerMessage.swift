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
        
        // MARK: - Requests
        
        case createSession(playlist_id: Int, shuffle: Bool)
        
        case removeSession
        
        case playTrack(player_session_id: Int, track_id: Int)
        
        case delayPlayTrack(player_session_id: Int, track_id: Int)
        
        case playNextTrack(player_session_id: Int, track_id: Int?)
        
        case playPreviousTrack(player_session_id: Int, track_id: Int?)
        
        case shuffle(player_session_id: Int, track_id: Int?)
        
        case pauseTrack(player_session_id: Int, track_id: Int?)
        
        case resumeTrack(player_session_id: Int, track_id: Int?)
        
        case stopTrack(player_session_id: Int, track_id: Int?)
        
        case syncTrack(player_session_id: Int, progress: Int)
        
        // MARK: - Responses
        
        case session(player_session: PlayerSession?)
        
        case sessionChanged(player_session: PlayerSession?)
    }
    
    public let payload: Payload
}
