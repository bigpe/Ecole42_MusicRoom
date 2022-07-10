//
//  DiskCacheService.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 04.07.2022.
//

import Foundation

public enum DiskCacheService<Entity: Codable> {
    private static func fileURL(name: String) throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent("\(Entity.self)+\(name).data")
    }
    
    public static func entity(name: String) async throws -> Entity {
        try await Task { () -> Entity in
            let fileURL = try fileURL(name: name)
            
            let file = try FileHandle(forReadingFrom: fileURL)
            
            let cachedEntity = try API.Decoder().decode(
                Entity.self,
                from: file.availableData
            )
            
            return cachedEntity
        }
        .value
    }
    
    public static func updateEntity(_ entity: Entity?, name: String) async throws {
        try await Task {
            let fileURL = try fileURL(name: name)
            
            guard
                let entity = entity
            else {
                try FileManager
                    .default
                    .removeItem(atPath: fileURL.absoluteString)
                
                return
            }
            
            let entityData = try API.Encoder()
                .encode(entity)
            
            try entityData
                .write(to: fileURL)
        }
        .value
    }
}
