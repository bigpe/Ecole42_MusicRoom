//
//  APICredential.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

public struct TokenDtoModel: Codable, Hashable {
    
    /** Access JWT token. Short lifetime */
    public var accessToken: String
    
    /** Refresh JWT token. Long lifetime */
    public var refreshToken: String
    
    /** Access JWT expiration in seconds */
    public var expiresIn: Int
    
    public init(
        accessToken: String,
        refreshToken: String,
        expiresIn: Int
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(accessToken)
        hasher.combine(refreshToken)
        hasher.combine(expiresIn)
    }
}

public struct APICredential: Codable, AuthenticationCredential {
    public let token: TokenDtoModel
    
    public let createdAt: Date
    
    public init(
        token: TokenDtoModel,
        createdAt: Date
    ) {
        self.token = token
        self.createdAt = createdAt
    }
    
    // MARK: - AuthenticationCredential
    
    public var requiresRefresh: Bool {
        let expirationDate = createdAt.addingTimeInterval(TimeInterval(token.expiresIn) + 60)
        let nowDate = Date()
        
        debugPrint(token.expiresIn, nowDate, expirationDate, nowDate >= expirationDate)
        
        return nowDate >= expirationDate
    }
}
