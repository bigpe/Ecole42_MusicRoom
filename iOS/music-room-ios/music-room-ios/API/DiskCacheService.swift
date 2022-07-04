//
//  DiskCacheService.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 04.07.2022.
//

import Foundation

public enum DiskCacheService<Entity: Codable> {
    private static var fileURL: URL {
        get throws {
            try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            .appendingPathComponent("\(Entity.self).data")
        }
    }
    
    public static var entity: Entity {
        get async throws {
            try await Task { () -> Entity in
                let fileURL = try fileURL
                
                let file = try FileHandle(forReadingFrom: fileURL)
                
                let cachedEntity = try JSONDecoder().decode(
                    Entity.self,
                    from: file.availableData
                )
                
                return cachedEntity
            }
            .value
        }
    }
    
    public static func updateEntity(_ entity: Entity?) async throws {
        try await Task {
            guard
                let fileURL = try fileURL
            else {
                return
            }
            
            guard
                let entity = entity
            else {
                try FileManager
                    .default
                    .removeItem(atPath: fileURL.absoluteString)
                
                return
            }
            
            let entityData = try JSONEncoder()
                .encode(entity)
            
            try entityData
                .write(to: fileURL)
        }
        .value
    }
}
