//
//  PlayerWebSocket.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 18.06.2022.
//

import Foundation

public class PlayerWebSocket {
    public var isSubscribed = false
    
    private let webSocketTask: URLSessionWebSocketTask
    
    // MARK: - Send Event
    
    public func send(_ event: PlayerEventsList) async throws {
        try await webSocketTask.send(.string(event.rawValue))
    }
    
    // MARK: - Receive Event
    
    public func receive() async throws -> PlayerEventsList {
        let message = try await webSocketTask.receive()
        
        guard
            case let .string(rawValue) = message,
            let event = PlayerEventsList(rawValue: rawValue)
        else {
            throw NSError()
        }
        
        return event
    }
    
    // MARK: - Events
    
    public func sessionChanged() async throws {
        try await send(.sessionChanged)
    }
    
    public func createSession() async throws {
        try await send(.createSession)
    }
    
    public func removeSession() async throws {
        try await send(.removeSession)
    }
    
    public func playTrack() async throws {
        try await send(.playTrack)
    }
    
    public func playNextTrack() async throws {
        try await send(.playNextTrack)
    }
    
    public func playPreviousTrack() async throws {
        try await send(.playPreviousTrack)
    }
    
    public func shuffle() async throws {
        try await send(.shuffle)
    }
    
    public func pauseTrack() async throws {
        try await send(.pauseTrack)
    }
    
    public func resumeTrack() async throws {
        try await send(.resumeTrack)
    }
    
    public func stopTrack() async throws {
        try await send(.stopTrack)
    }
    
    public func onReceive(_ block: @escaping (PlayerEventsList) -> Void) {
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
            let url = URL(string: "wss://music-room-test.herokuapp.com/ws/player/\(userID)/")
        else {
            throw NSError()
        }
        
        webSocketTask = URLSession.shared.webSocketTask(with: URLRequest(url: url))
        
        webSocketTask.resume()
    }
}
