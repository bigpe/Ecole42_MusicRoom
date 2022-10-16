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
    
    lazy var playlistsWebSocket = try? PlaylistsWebSocket(api: self)
    
    lazy var playlistWebSockets = [Int: PlaylistWebSocket]()
    
    func playlistWebSocket(playlistID: Int) -> PlaylistWebSocket? {
        guard
            let playlistWebSocket = playlistWebSockets[playlistID]
        else {
            let playlistWebSocket = try? PlaylistWebSocket(api: self, playlistID: playlistID)
            
            playlistWebSockets[playlistID] = playlistWebSocket
            
            return playlistWebSocket
        }
        
        return playlistWebSocket
    }
    
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
        URL(string: "https://api.musicroom.tech/")
    }
    
    public init() {
        URLSession.shared.configuration.waitsForConnectivity = true
        URLSession.shared.configuration.shouldUseExtendedBackgroundIdleMode = true
        
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
    ) async throws -> Result<APICredential, TokenRequestError> {
        let result: Result<TokenResponseModel, TokenRequestError> = try await AF.request(
            try authURL,
            method: .post,
            parameters: parameters,
            encoder: .apiJSON
        )
        .validate()
        .serializingAPI()
        .valueOrError()
        
        switch result {
        case .success(let token):
            let apiCredential = APICredential(token: token)
            
            keychainCredential = apiCredential
            
            return .success(apiCredential)
            
        case .failure(let error):
            return .failure(error)
        }
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
                .value
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
    
    // MARK: - Artist
    
    var artistURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "api/artist/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func artistsRequest() async throws -> [Artist] {
        try await session.request(
            try artistURL,
            method: .get
        )
        .validate()
        .serializingAPI()
        .value
    }
    
    // MARK: - Artist With ID
    
    var artistWithIDURL: (Int) throws -> URL {
        { [unowned self] (artistID) throws -> URL in
            guard
                let url =
                    URL(
                        string: "\(artistID)/",
                        relativeTo: try artistURL
                    )
            else { throw .api.invalidURL }

            return url
        }
    }
    
    public func artistRequest(artistID: Int) async throws -> Artist {
        try await session.request(
            try artistWithIDURL(artistID),
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
    
    // MARK: - Users
    
    var usersURL: URL {
        get throws {
            guard
                let url =
                    URL(
                        string: "api/users/",
                        relativeTo: baseURL
                    )
            else { throw .api.invalidURL }
            
            return url
        }
    }
    
    public func usersRequest() async throws -> [User] {
        try await session.request(
            try usersURL,
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
        try await session.request(
            try playerSessionURL,
            method: .get
        )
        .validate()
        .serializingAPI()
        .value
    }
}
