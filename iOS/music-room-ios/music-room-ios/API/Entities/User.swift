//
//  User.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 15.07.2022.
//

import Foundation

public struct User: Codable, Identifiable, Hashable {
    public let id: Int?
    
    public let username: String
    
    public let password: String
    
    public init(
        id: Int? = nil,
        username: String,
        password: String
    ) {
        self.id = id
        self.username = username
        self.password = password
    }
}
