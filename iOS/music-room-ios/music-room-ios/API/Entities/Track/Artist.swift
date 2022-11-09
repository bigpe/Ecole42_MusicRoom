import Foundation

public struct Artist: Codable, Identifiable, Hashable {
    public let id: Int?
    
    public let name: String
    
    public let tracks: [Track]
    
    public init(
        id: Int? = nil,
        name: String,
        tracks: [Track]
    ) {
        self.id = id
        self.name = name
        self.tracks = tracks
    }
}
