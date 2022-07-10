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
            encoder: API.Encoder()
        )
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
    
    lazy var playerWebSocket = try? PlayerWebSocket(api: self)
    
    lazy var playlistWebSocket = try? PlaylistWebSocket(api: self)
    
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
    
    public var session: Session!
    
    // MARK: - Base URL
    
    public var baseURL: URL? {
        URL(string: "https://music-room-test.herokuapp.com/")
    }
    
    public init() {
        session = cleanSession
    }
    
    // MARK: - Auth
    
    var authURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "api/auth/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func authRequest(
        _ parameters: TokenObtainPairModel
    ) async throws -> APICredential {
        let apiCredential = APICredential(
            token:
                try await AF.request(
                    try authURL,
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
    
    // MARK: - Refresh
    
    var authRefreshURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "token/refresh/",
                        relativeTo: try authURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func refreshRequest(
        _ parameters: TokenRefreshModel
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
        try await refreshRequest(TokenRefreshModel(refresh: token))
    }
    
    // MARK: - Sign Out
    
    public func signOut() {
        keychainCredential = nil
    }
    
    // MARK: - Playlists
    
    var playlistURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "api/playlist/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func playlistRequest() async throws -> [Playlist] {
        try await session.request(
            try playlistURL,
            method: .get
        )
        .validate()
        .serializingAPI()
        .value
    }
    
    // MARK: - Own Playlists
    
    var ownPlaylistURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "own/",
                        relativeTo: try playlistURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func ownPlaylistRequest() async throws -> [Playlist] {
        try await session.request(
            try ownPlaylistURL,
            method: .get
        )
        .validate()
        .serializingAPI()
        .value
    }
    
    // MARK: - Tracks
    
    var trackURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "api/track/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func trackRequest() async throws -> [Track] {
        try await session.request(
            try trackURL,
            method: .get
        )
        .validate()
        .serializingAPI()
        .value
    }
    
    // MARK: - Player Session
    
    var playerURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "api/player/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    var playerSessionURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "session/",
                        relativeTo: try playerURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func playerSessionRequest() async throws -> PlayerSession {
        let dataTask: DataTask<PlayerSession> = try await session.request(
            try playerSessionURL,
            method: .get
        ).serializingAPI()
        
        debugPrint(try await dataTask.response)
        
        return
        try await session.request(
            try playerSessionURL,
            method: .get
        )
        .validate()
        .serializingAPI()
        .value
    }
}
