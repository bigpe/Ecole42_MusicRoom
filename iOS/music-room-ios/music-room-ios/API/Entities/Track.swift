//
//  Track.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct Track: Codable, Identifiable, Hashable {
    public let id: Int?
    
    public let name: String
    
    public let files: [File]
    
    public init(
        id: Int? = nil,
        name: String,
        files: [File]
    ) {
        self.id = id
        self.name = name
        self.files = files
    }
}
