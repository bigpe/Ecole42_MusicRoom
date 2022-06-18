//
//  WebSocketPlaylist.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 18.06.2022.
//

import Foundation

public class WebSocketPlaylist {
    private let webSocketTask: URLSessionWebSocketTask
    
    public func playlistChanged() async throws {
        try await webSocketTask.send(.string("playlist.changed"))
    }
    
    public func playlistsChanged() async throws {
        try await webSocketTask.send(.string("playlists.changed"))
    }
    
    public func renamePlaylist() async throws {
        try await webSocketTask.send(.string("rename.playlist"))
    }
    
    public func addPlaylist() async throws {
        try await webSocketTask.send(.string("add.playlist"))
    }
    
    public func removePlaylist() async throws {
        try await webSocketTask.send(.string("remove.playlist"))
    }
    
    public func addTrack() async throws {
        try await webSocketTask.send(.string("add.track"))
    }
    
    public func removeTrack() async throws {
        try await webSocketTask.send(.string("remove.track"))
    }
    
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
