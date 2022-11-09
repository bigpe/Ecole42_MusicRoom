import Foundation

public struct TokenRefresh: Codable, Hashable {
    public var access: String?
    
    public var refresh: String
    
    public init(access: String? = nil, refresh: String) {
        self.access = access
        self.refresh = refresh
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(access)
        hasher.combine(refresh)
    }
}
