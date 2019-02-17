import Foundation

public struct Dependency {
    public let name: String?
    public var url: URL
    
    public init(name: String? = nil, url: URL) {
        self.name = name
        self.url = url
    }
}

extension Dependency: Equatable {
    public static func ==(lhs: Dependency, rhs: Dependency) -> Bool {
        return
            lhs.name == rhs.name
            && lhs.url == rhs.url
    }
}
