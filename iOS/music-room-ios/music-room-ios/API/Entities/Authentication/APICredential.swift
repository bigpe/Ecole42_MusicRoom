//
//  APICredential.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

public struct APICredential: Codable, AuthenticationCredential {
    public let token: Token
    
    public init(
        token: Token
    ) {
        self.token = token
    }
    
    // MARK: - AuthenticationCredential
    
    public var requiresRefresh: Bool {
        Date().addingTimeInterval(60) >= token.expiresIn
    }
}
