//
//  PlaylistWebSocket.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 18.06.2022.
//

import Foundation

public class PlaylistWebSocket {
    
    private weak var api: API!
    
    public var isSubscribed = false
    
    private let webSocketTask: URLSessionWebSocketTask
    
    // MARK: - Send Event
    
    public func send(_ event: PlaylistEventsList) async throws {
        try await webSocketTask.send(.string(event.rawValue))
    }
    
    // MARK: - Receive Event
    
    public func receive() async throws -> PlaylistEventsList {
        let message = try await webSocketTask.receive()
        
        guard
            case let .string(rawValue) = message,
            let event = PlaylistEventsList(rawValue: rawValue)
        else {
            throw NSError()
        }
        
        return event
    }
    
    // MARK: - Events
    
    public func playlistChanged() async throws {
        try await send(.playlistChanged)
    }
    
    public func onReceive(_ block: @escaping (PlaylistEventsList) -> Void) {
        isSubscribed = true
        
        Task {
            defer {
                onReceive(block)
            }
            
            block(try await receive())
        }
    }
    
    // MARK: - Init with API
    
    public init(api: API) throws {
        guard
            let url =
                URL(
                    string: "ws/playlist/",
                    relativeTo: api.baseURL
                ),
            let accessToken = api.keychainCredential?.token.access
        else {
            throw NSError()
        }
        
        var request = URLRequest(url: url)
        
        request.headers.add(
            name: "Authorization",
            value: "Bearer \(accessToken)"
        )
        
        webSocketTask = URLSession.shared.webSocketTask(with: request)

        webSocketTask.resume()
    }
}
