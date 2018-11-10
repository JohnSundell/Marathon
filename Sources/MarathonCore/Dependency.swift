import Foundation

public struct Dependency {
    public let name: String?
    public let url: URL
}

extension Dependency: Equatable {
    public static func ==(lhs: Dependency, rhs: Dependency) -> Bool {
        return
            lhs.name == rhs.name
            && lhs.url == rhs.url
    }
}
