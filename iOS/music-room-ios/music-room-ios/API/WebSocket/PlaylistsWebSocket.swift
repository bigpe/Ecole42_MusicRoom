//
//  PlaylistsWebSocket.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 18.06.2022.
//

import Foundation

public class PlaylistsWebSocket {
    
    private weak var api: API!
    
    public var isSubscribed = false
    
    private let webSocketTask: URLSessionWebSocketTask
    
    // MARK: - Send Event
    
    public func send(_ message: PlaylistsMessage) async throws {
        let encodedMessageData = try API.Encoder().encode(message)
        
        guard
            let encodedMessageString = String(data: encodedMessageData, encoding: .utf8)
        else {
            throw .api.custom(errorDescription: "Can't encode message")
        }
        
        try await webSocketTask.send(.string(encodedMessageString))
    }
    
    // MARK: - Receive Message
    
    public func receive() async throws -> PlaylistsMessage {
        let message = try await webSocketTask.receive()
        
        guard
            case let .string(rawValue) = message,
            let data = rawValue.data(using: .utf8)
        else {
            throw .api.custom(errorDescription: "Playlist WebSocket")
        }
        
        do {
            let playlistsMessage = try API.Decoder().decode(PlaylistsMessage.self, from: data)
            
            return playlistsMessage
        } catch {
            
            print(rawValue, "\n\n")
            print(error)
            
            throw error
        }
    }
    
    // MARK: - Events
    
    public func onReceive(_ block: @escaping (PlaylistsMessage) -> Void) {
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
