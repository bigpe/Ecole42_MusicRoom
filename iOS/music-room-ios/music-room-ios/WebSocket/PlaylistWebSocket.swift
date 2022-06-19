//
//  PlaylistWebSocket.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 18.06.2022.
//

import Foundation

public class PlaylistWebSocket {
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
    
    public func playlistsChanged() async throws {
        try await send(.playlistsChanged)
    }
    
    public func renamePlaylist() async throws {
        try await send(.renamePlaylist)
    }
    
    public func addPlaylist() async throws {
        try await send(.addPlaylist)
    }
    
    public func removePlaylist() async throws {
        try await send(.removePlaylist)
    }
    
    public func addTrack() async throws {
        try await send(.addTrack)
    }
    
    public func removeTrack() async throws {
        try await send(.removeTrack)
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
    
    // MARK: - Init with UserID
    
    public init(userID: String) throws {
        guard
            let url = URL(string: "wss://music-room-test.herokuapp.com/ws/playlist/\(userID)/")
        else {
            throw NSError()
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: URLRequest(url: url))
        
        webSocketTask.resume()
    }
}
