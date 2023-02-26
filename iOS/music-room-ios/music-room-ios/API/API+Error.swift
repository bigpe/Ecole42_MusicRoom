//
//  API+Error.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Foundation

extension API {
    public enum APIError: Error, Equatable {
        case invalidURL, invalidRequest, invalidResponse
        
        public enum Keychain: Equatable {
            case unableToAdd, unableToUpdate
        }
        
        case keychain(Keychain)
        
        case custom(errorDescription: String)
    }
}

extension API.APIError: LocalizedError {
    public var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
            
        case .invalidRequest:
            return "Invalid request"
            
        case .invalidResponse:
            return "Invalid response"
            
        case .keychain(let keychain):
            switch keychain {
            case .unableToAdd:
                return "Unable to add Token to Keychain"
                
            case .unableToUpdate:
                return "Unable to update Token on Keychain"
            }
            
        case .custom(let errorDescription):
            return errorDescription
        }
    }
}

extension API.APIError: CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
            
        case .invalidRequest:
            return "Invalid request"
            
        case .invalidResponse:
            return "Invalid response"
            
        case .keychain(let keychain):
            switch keychain {
            case .unableToAdd:
                return "Unable to add Token to Keychain"
                
            case .unableToUpdate:
                return "Unable to update Token on Keychain"
            }
            
        case .custom(let errorDescription):
            return errorDescription
        }
    }
}

extension Error {
    public typealias api = API.APIError
}
