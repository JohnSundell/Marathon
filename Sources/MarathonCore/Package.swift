/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Releases

public struct Package: Codable {
    public let name: String
    public let url: URL
    public var majorVersion: Int
}

extension Package: Equatable {
    public static func ==(lhs: Package, rhs: Package) -> Bool {
        return lhs.url == rhs.url && lhs.majorVersion == rhs.majorVersion
    }
}

internal extension Package {
    var folderPrefix: String {
        if url.isForRemoteRepository {
            return "\(name).git-"
        }

        return "\(name)-"
    }

    func dependencyString(forSwiftToolsVersion toolsVersion: Version) -> String {
        if toolsVersion.major == 3 {
            return ".Package(url: \"\(url.absoluteString)\", majorVersion: \(majorVersion))"
        }

        return ".package(url: \"\(url.absoluteString)\", from: \"\(majorVersion).0.0\")"
    }
}

internal extension Package {
    struct Pinned: Decodable {
        enum CodingKeys: String, CodingKey {
            case name = "package"
            case url = "repositoryURL"
            case state
        }

        struct State {
            let version: Version
        }

        let name: String
        let url: URL
        let state: State
    }
}

extension Package.Pinned.State: Decodable {
    enum CodingKeys: CodingKey {
        case version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let versionString = try container.decode(String.self, forKey: .version)
        version = try Version(string: versionString)
    }
}
