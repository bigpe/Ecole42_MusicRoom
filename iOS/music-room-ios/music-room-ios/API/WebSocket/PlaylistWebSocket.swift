//
//  PlaylistWebSocket.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 12.07.2022.
//

import Foundation

public class PlaylistWebSocket {
    
    private weak var api: API!
    
    public var isSubscribed: Bool {
        receiveBlock != nil
    }
    
    private let webSocketTask: URLSessionWebSocketTask
    
    // MARK: - Send Event
    
    public func send(_ message: PlaylistMessage) async throws {
        let encodedMessageData = try API.Encoder().encode(message)
        
        guard
            let encodedMessageString = String(data: encodedMessageData, encoding: .utf8)
        else {
            throw .api.custom(errorDescription: "Can't encode message")
        }
        
        try await webSocketTask.send(.string(encodedMessageString))
    }
    
    // MARK: - Receive Message
    
    private var receiveUUID: UUID?
    
    private var receiveBlock: ((PlaylistMessage) -> Void)? {
        didSet {
            guard
                receiveBlock != nil
            else {
                return
            }
            
            let uuid = UUID()
            
            receiveUUID = uuid
            
            receive(uuid)
        }
    }
    
    public func receive(_ uuid: UUID) {
        Task {
            guard
                uuid == receiveUUID,
                let receiveBlock = receiveBlock
            else {
                return
            }
            
            defer {
                receive(uuid)
            }
            
            let message = try await webSocketTask.receive()
            
            guard
                case let .string(rawValue) = message,
                let data = rawValue.data(using: .utf8)
            else {
                throw .api.custom(errorDescription: "Playlist WebSocket")
            }
            
            do {
                let playlistMessage = try API.Decoder().decode(PlaylistMessage.self, from: data)
                
                receiveBlock(playlistMessage)
            } catch {
                
                print(rawValue, "\n\n")
                print(error)
                
                throw error
            }
        }
    }
    
    // MARK: - Events
    
    public func onReceive(_ block: @escaping (PlaylistMessage) -> Void) {
        receiveBlock = block
    }
    
    // MARK: - Init with API
    
    public init(api: API, playlistID: Int) throws {
        guard
            let url =
                URL(
                    string: "ws/playlist/\(playlistID)/",
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
