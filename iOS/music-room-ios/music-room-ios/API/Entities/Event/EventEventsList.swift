import Foundation

public enum EventEventsList: String, Codable {
    
    // MARK: - Requests
    
    case playTrack = "play.track"
    
    case delayPlayTrack = "delay.play.track"
    
    case playNextTrack = "play.next.track"
    
    case playPreviousTrack = "play.previous.track"
    
    case shuffle = "shuffle"
    
    case pauseTrack = "pause.track"
    
    case resumeTrack = "resume.track"
    
    case stopTrack = "stop.track"
    
    case syncTrack = "sync.track"
    
    case voteTrack = "vote.track"
    
    case changeEvent = "change.event"
    
    case addTrack = "add.track"
    
    case removeTrack = "remove.track"
    
    case inviteToEvent = "invite.to.event"
    
    case revokeFromEvent = "revoke.from.event"
    
    case changeUserAccessMode = "change.user.access.mode"
    
    // MARK: - Responses
    
    case session = "session"
    
    case sessionChanged = "session.changed"
    
    case eventChanged = "event.changed"
}
