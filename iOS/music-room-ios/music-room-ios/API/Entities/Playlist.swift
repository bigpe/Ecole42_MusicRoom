//
//  Playlist.swift
//  music-room-ios
//
//  Created by Nikita Arutyunov on 19.06.2022.
//

import Foundation
import UIKit

public struct Playlist: Codable, Identifiable {
    public let id: Int?
    
    public let tracks: [PlaylistTrack]
    
    public let name: String
    
    public enum `Type`: String, Codable {
        case `default`, custom
    }
    
    public let type: `Type`?
    
    public enum AccessType: String, Codable, CaseIterable, Identifiable, CustomStringConvertible {
        case `public`, `private`
        
        public var id: Self { self }
        
        public var description: String {
            switch self {
                
            case .public:
                return "Public"
                
            case .private:
                return "Private"
            }
        }
    }
    
    public let accessType: AccessType
    
    public let author: Int
    
    public init(
        id: Int? = nil,
        tracks: [PlaylistTrack],
        name: String,
        type: `Type`? = nil,
        accessType: AccessType,
        author: Int
    ) {
        self.id = id
        self.tracks = tracks
        self.name = name
        self.type = type
        self.accessType = accessType
        self.author = author
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case tracks
        case name
        case type
        case accessType = "access_type"
        case author
    }
    
    var defaultCover: UIImage {
        generateImage(
            CGSize(width: 1000, height: 1000),
            rotatedContext: { size, context in
                
                context.clear(CGRect(origin: CGPoint(), size: size))
                
                let musicNoteIcon = UIImage(systemName: "music.note.list")?
                    .withConfiguration(UIImage.SymbolConfiguration(
                        pointSize: 1000 * 0.375,
                        weight: .medium
                    ))
                ?? UIImage()
                
                drawIcon(
                    context: context,
                    size: size,
                    icon: musicNoteIcon,
                    iconSize: musicNoteIcon.size,
                    iconColor: UIColor(displayP3Red: 0.462, green: 0.458, blue: 0.474, alpha: 1),
                    backgroundColors: [
                        UIColor(displayP3Red: 0.33, green: 0.325, blue: 0.349, alpha: 1),
                        UIColor(displayP3Red: 0.33, green: 0.325, blue: 0.349, alpha: 1),
                    ],
                    id: id
                )
            }
        )?
            .withRenderingMode(.alwaysOriginal) ?? UIImage()
    }
    
    var cover: UIImage {
//        guard
//            let firstLetter = name.first
//        else {
//            return nil
//        }
//
//        let letters = [String(firstLetter)]
        
        let letters = name.map { String($0) }

        return generateImage(
            CGSize(width: 1000, height: 1000),
            rotatedContext: { contextSize, context in

                context.clear(CGRect(origin: CGPoint(), size: contextSize))

                drawLetters(
                    context: context,
                    size: CGSize(width: contextSize.width, height: contextSize.height),
                    round: false,
                    letters: letters,
                    foregroundColor: UIColor(displayP3Red: 0.462, green: 0.458, blue: 0.474, alpha: 1),
                    backgroundColors: [
                        UIColor(displayP3Red: 0.33, green: 0.325, blue: 0.349, alpha: 1),
                        UIColor(displayP3Red: 0.33, green: 0.325, blue: 0.349, alpha: 1),
                    ],
                    id: id
                )
            }
        )?
            .withRenderingMode(.alwaysOriginal)
        
        ?? defaultCover
    }
}
