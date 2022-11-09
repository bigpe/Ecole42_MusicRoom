import Foundation
import UIKit

public struct EventCreate: Codable {
    public let id: Int?
    
    public let playlist: Int?
    
    public let name: String
    
    public enum AccessType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
        case `public`, `private`
        
        public var id: Self { self }
        
        public var description: String {
            switch self {
                
            case .public:
                return "Public"
                
            case .private:
                return "Private"
            }
        }
    }
    
    public let accessType: AccessType
    
    public let startDate: Date
    
    public let endDate: Date
    
    public let isFinished: Bool?
    
    public let author: Int?
    
    public let playerSession: Int?
    
    public init(
        id: Int? = nil,
        playlist: Int? = nil,
        name: String,
        accessType: AccessType,
        startDate: Date,
        endDate: Date,
        isFinished: Bool? = nil,
        author: Int? = nil,
        playerSession: Int? = nil
    ) {
        self.id = id
        self.playlist = playlist
        self.name = name
        self.accessType = accessType
        self.startDate = startDate
        self.endDate = endDate
        self.isFinished = isFinished
        self.author = author
        self.playerSession = playerSession
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case playlist
        case name
        case accessType = "access_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case isFinished = "is_finished"
        case author
        case playerSession = "player_session"
    }
}
