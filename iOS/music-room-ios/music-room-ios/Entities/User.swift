//
//  User.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation

public struct User: Codable {
    public let id: Int?
    
    public let username: String
    
    public let password: String
    
    public let password2: String
    
    public init(
        id: Int? = nil,
        username: String,
        password: String,
        password2: String
    ) {
        self.id = id
        self.username = username
        self.password = password
        self.password2 = password2
    }
}
