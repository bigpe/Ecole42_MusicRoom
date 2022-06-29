//
//  Track.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct Track: Codable, Identifiable {
    public let id: Int?
    
    public let name: String
    
    public let file: String?
    
    public let duration: Decimal?
    
    public init(
        id: Int? = nil,
        name: String,
        file: String? = nil,
        duration: Decimal? = nil
    ) {
        self.id = id
        self.name = name
        self.file = file
        self.duration = duration
    }
}
