//
//  WebSocketPlayer.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 18.06.2022.
//

import Foundation

public class WebSocketPlayer {
    private let webSocketTask: URLSessionWebSocketTask
    
    public func sessionChanged() async throws {
        try await webSocketTask.send(.string("session.changed"))
    }
    
    public func createSession() async throws {
        try await webSocketTask.send(.string("create.session"))
    }
    
    public func removeSession() async throws {
        try await webSocketTask.send(.string("remove.session"))
    }
    
    public func playTrack() async throws {
        try await webSocketTask.send(.string("play.track"))
    }
    
    public func playNextTrack() async throws {
        try await webSocketTask.send(.string("play.next.track"))
    }
    
    public func playPreviousTrack() async throws {
        try await webSocketTask.send(.string("play.previous.track"))
    }
    
    public func shuffle() async throws {
        try await webSocketTask.send(.string("shuffle"))
    }
    
    public func pauseTrack() async throws {
        try await webSocketTask.send(.string("pause.track"))
    }
    
    public func resumeTrack() async throws {
        try await webSocketTask.send(.string("resume.track"))
    }
    
    public func stopTrack() async throws {
        try await webSocketTask.send(.string("stop.track"))
    }
    
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
