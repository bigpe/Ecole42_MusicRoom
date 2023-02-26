import Foundation

public struct Track: Codable, Identifiable, Hashable {
    public let id: Int?
    
    public let name: String
    
    public let artist: Int
    
    public let files: [File]
    
    public var meta: (title: String, artist: String?) {
        let title = name
            .split(separator: "—")
            .dropFirst()
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard
            !title.isEmpty,
            let artist = name
                .split(separator: "—")
                .first?
                .description
                .trimmingCharacters(in: .whitespacesAndNewlines),
            !artist.isEmpty
        else {
            return (name, nil)
        }
        
        return (title, artist)
    }
    
    public init(
        id: Int? = nil,
        name: String,
        artist: Int,
        files: [File]
    ) {
        self.id = id
        self.name = name
        self.artist = artist
        self.files = files
    }
}
