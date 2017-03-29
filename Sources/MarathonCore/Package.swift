/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Unbox

public struct Package {
    public let name: String
    public let url: URL
    public var majorVersion: Int
}

extension Package: Equatable {
    public static func ==(lhs: Package, rhs: Package) -> Bool {
        return lhs.url == rhs.url && lhs.majorVersion == rhs.majorVersion
    }
}

extension Package: Unboxable {
    public init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "name")
        url = try unboxer.unbox(key: "url")
        majorVersion = try unboxer.unbox(key: "majorVersion")
    }
}

internal extension Package {
    var dependencyString: String {
        return ".Package(url: \"\(url.absoluteString)\", majorVersion: \(majorVersion))"
    }

    var folderPrefix: String {
        if url.isForRemoteRepository {
            return "\(name).git-"
        }

        return "\(name)-"
    }
}
