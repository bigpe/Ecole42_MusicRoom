import Foundation
import UIKit

public struct EventList: Codable, Identifiable {
    public let id: Int?
    
    public let name: String
    
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
    
    public let startDate: Date
    
    public let endDate: Date
    
    public let isFinished: Bool?
    
    public let author: Int
    
    public let playerSession: Int?
    
    public init(
        id: Int? = nil,
        name: String,
        accessType: AccessType,
        startDate: Date,
        endDate: Date,
        isFinished: Bool? = nil,
        author: Int,
        playerSession: Int? = nil
    ) {
        self.id = id
        self.name = name
        self.accessType = accessType
        self.startDate = startDate
        self.endDate = endDate
        self.isFinished = isFinished
        self.author = author
        self.playerSession = playerSession
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case accessType = "access_type"
        case startDate = "start_date"
        case endDate = "end_date"
        case isFinished = "is_finished"
        case author
        case playerSession = "player_session"
    }
    
    var cover: UIImage {
        generateImage(
            CGSize(width: 1000, height: 1000),
            rotatedContext: { contextSize, context in

                context.clear(CGRect(origin: CGPoint(), size: contextSize))
                
                let cornerIconPointSize = contextSize.width * 0.175

                let musicNoteIcon = UIImage(systemName: "party.popper.fill")?
                    .withConfiguration(UIImage.SymbolConfiguration(
                        pointSize: cornerIconPointSize,
                        weight: .regular
                    ))
                ?? UIImage()
                
                var lockIcon: UIImage?
                
                if accessType == .private {
                    lockIcon = UIImage(systemName: "lock.circle.fill")?
                        .withConfiguration(UIImage.SymbolConfiguration(
                            pointSize: cornerIconPointSize,
                            weight: .regular
                        ))
                }
                
                drawLetters(
                    context: context,
                    size: CGSize(width: contextSize.width, height: contextSize.height),
                    round: false,
                    topCornerIcon: musicNoteIcon,
                    bottomCornerIcon: lockIcon,
                    letters: name.map { String($0) },
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
        
        ?? UIImage()
    }
}
