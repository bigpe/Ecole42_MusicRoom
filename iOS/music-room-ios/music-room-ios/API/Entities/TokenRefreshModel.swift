//
//  TokenRefreshModel.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 04.07.2022.
//

import Foundation

public struct TokenRefreshModel: Codable, Hashable {
    public var access: String?
    
    public var refresh: String
    
    public init(access: String? = nil, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(access)
        hasher.combine(refresh)
    }
}
