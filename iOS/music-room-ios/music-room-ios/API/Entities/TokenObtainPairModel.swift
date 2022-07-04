//
//  TokenObtainPairModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 04.07.2022.
//

import Foundation

public struct TokenObtainPairModel: Codable, Hashable {
    public var username: String
    
    public var password: String
    
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(username)
        hasher.combine(password)
    }
}
