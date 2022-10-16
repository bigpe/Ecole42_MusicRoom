import Foundation

public struct TokenRequestError: Error, Decodable {
    public var username: [String]?
    
    public var password: [String]?
}
