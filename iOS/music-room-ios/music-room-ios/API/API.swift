//
//  API.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 27.06.2022.
//

import Alamofire
import Foundation

public typealias DateTime = Date
public typealias DateDay = Date

extension ParameterEncoder where Self == JSONParameterEncoder {
    /// Provides a default `JSONParameterEncoder` instance.
    public static var apiJSON: JSONParameterEncoder {
        JSONParameterEncoder(
            encoder: {
                let encoder = JSONEncoder()
                
                encoder.dateEncodingStrategy = .formatted(
                    {
                        let dateFormatter = DateFormatter()
                        
                        dateFormatter.calendar = Calendar(identifier: .iso8601)
                        
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
                        
                        return dateFormatter
                    }()
                )
                
                return encoder
            }()
        )
    }
}

public struct RefreshTokenRequestDtoModel: Codable, Hashable {
    
    /** Refresh token */
    public var refreshToken: String
    
    public init(
        refreshToken: String
    ) {
        self.refreshToken = refreshToken
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(refreshToken)
    }
}

public class API {
    public lazy var closureEventMonitor: ClosureEventMonitor = {
        let monitor = ClosureEventMonitor()
        
        return monitor
    }()
    
    public lazy var eventMonitors = [
        closureEventMonitor
    ]
    
    // MARK: - Web Socket
    
    private static let testUserID = "55"
    
    let playerWebSocket = try? PlayerWebSocket(userID: testUserID)
    
    let playlistWebSocket = try? PlaylistWebSocket(userID: testUserID)
    
    // MARK: - Authentication
    
    private lazy var authenticator = APIAuthenticator(refreshToken: refreshToken)
    
    public var authenticationInterceptor: APIInterceptor? {
        guard let credential = keychainCredential else { return nil }
        
        let interceptor = APIInterceptor(
            authenticator: authenticator,
            credential: credential
        )
        
        return interceptor
    }
    
    public var isAuthorized: Bool {
        keychainCredential != nil
    }
    
    // MARK: - Session
    
    var cleanSession: Session {
        let configuration = URLSessionConfiguration.af.default
        
        let session = Session(
            configuration: configuration,
            interceptor: authenticationInterceptor,
            eventMonitors: eventMonitors
        )
        
        return session
    }
    
    public lazy var session: Session = cleanSession
    
    // MARK: - Base URL
    
    public var baseURL: URL? {
        URL(string: "https://snbf3muzcc.execute-api.us-east-1.amazonaws.com/dev/")
    }
    
    public init() {}
    
    // MARK: - Refresh
    
    var authRefreshURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "auth/refresh/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func refresh(
        _ parameters: RefreshTokenRequestDtoModel
    ) async throws -> APICredential {
        let apiCredential = APICredential(
            token:
                try await AF.request(
                    try authRefreshURL,
                    method: .post,
                    parameters: parameters,
                    encoder: .apiJSON
                )
                .validate()
                .serializingAPI()
                .value,
            createdAt: Date()
        )
        
        keychainCredential = apiCredential
        
        return apiCredential
    }
    
    public func refreshToken(_ token: String) async throws -> APICredential {
        try await refresh(RefreshTokenRequestDtoModel(refreshToken: token))
    }
}
