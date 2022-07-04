//
//  APICredential.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

public struct APICredential: Codable, AuthenticationCredential {
    public let token: TokenRefreshModel
    
    public let createdAt: Date
    
    public init(
        token: TokenRefreshModel,
        createdAt: Date
    ) {
        self.token = token
        self.createdAt = createdAt
    }
    
    // MARK: - AuthenticationCredential
    
    public var requiresRefresh: Bool {
        false
    }
}
