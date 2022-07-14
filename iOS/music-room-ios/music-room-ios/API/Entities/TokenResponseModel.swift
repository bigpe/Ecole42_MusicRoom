//
//  TokenResponseModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 14.07.2022.
//

import Foundation

public struct TokenResponseModel: Codable, Hashable {
    public var access: String
    
    public var refresh: String
    
    public var expiresIn: Date
    
    public init(access: String, refresh: String, expiresIn: Date) {
        self.access = access
        self.refresh = refresh
        self.expiresIn = expiresIn
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(access)
        hasher.combine(refresh)
        hasher.combine(expiresIn)
    }
    
    enum CodingKeys: String, CodingKey {
        case access, refresh, expiresIn = "expires_in"
    }
}
