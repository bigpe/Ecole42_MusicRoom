//
//  PlayerEventsList.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public enum PlayerEventsList: String, Codable {
    case sessionChanged = "session.changed"
    
    case createSession = "create.session"
    
    case removeSession = "remove.session"
    
    case playTrack = "play.track"
    
    case playNextTrack = "play.next.track"
    
    case playPreviousTrack = "play.previous.track"
    
    case shuffle = "shuffle"
    
    case pauseTrack = "pause.track"
    
    case resumeTrack = "resume.track"
    
    case stopTrack = "stop.track"
}