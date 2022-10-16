import Foundation

public struct File: Codable, Identifiable, Hashable {
    public let id: Int?
    
    public let file: String
    
    public enum Extension: String, Codable {
        case mp3, flac
    }
    
    public let `extension`: Extension
    
    public let duration: Decimal
    
    public let track: Int
    
    public init(
        id: Int? = nil,
        file: String,
        extension: Extension,
        duration: Decimal,
        track: Int
    ) {
        self.id = id
        self.file = file
        self.`extension` = `extension`
        self.duration = duration
        self.track = track
    }
}
