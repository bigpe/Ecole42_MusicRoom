import Foundation
import UIKit

public struct PlaylistAccess: Codable, Identifiable {
    public let id: Int?
    
    public let user: User?
    
    public let playlist: Playlist?
}
