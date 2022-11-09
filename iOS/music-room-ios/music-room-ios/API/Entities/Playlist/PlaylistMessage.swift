import Foundation

public struct PlaylistMessage: Codable {
    public let event: PlaylistEventsList
    
    public enum Payload: Codable {
        
        // MARK: - Requests
        
        case addTrack(track_id: Int)
        
        case removeTrack(track_id: Int)
        
        case inviteToPlaylist(user_id: Int)
        
        case revokeFromPlaylist(user_id: Int)
        
        // MARK: - Responses
        
        case playlistChanged(playlist: Playlist)
    }
    
    public let payload: Payload
}
