import Foundation

public struct EventMessage: Codable {
    public let event: EventEventsList
    
    public enum Payload: Codable {
        
        // MARK: - Requests
        
        case playTrack(player_session_id: Int, track_id: Int)
        
        case delayPlayTrack(player_session_id: Int, track_id: Int)
        
        case playNextTrack(player_session_id: Int, track_id: Int?)
        
        case playPreviousTrack(player_session_id: Int, track_id: Int?)
        
        case shuffle(player_session_id: Int, track_id: Int?)
        
        case pauseTrack(player_session_id: Int, track_id: Int?)
        
        case resumeTrack(player_session_id: Int, track_id: Int?)
        
        case stopTrack(player_session_id: Int, track_id: Int?)
        
        case syncTrack(player_session_id: Int, progress: Int)
        
        case voteTrack(player_session_id: Int, track_id: Int)
        
        case changeEvent(event_name: String, event_access_type: String)
        
        case addTrack(player_session_id: Int, track_id: Int)
        
        case removeTrack(player_session_id: Int, session_track_id: Int)
        
        case inviteToEvent(user_id: Int)
        
        case revokeFromEvent(user_id: Int)
        
        case changeUserAccessMode(user_id: Int, access_mode: String)
        
        // MARK: - Responses
        
        case session(player_session: PlayerSession?)
        
        case sessionChanged(player_session: PlayerSession?)
        
        case eventChanged(event: Event)
    }
    
    public let payload: Payload
}
