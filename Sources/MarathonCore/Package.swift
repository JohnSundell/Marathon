/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Unbox
import Releases

public struct Package {
    public let name: String
    public let url: URL
    public var version: Version
    public var majorVersion: Int { return version.major }
}

extension Package: Equatable {
    public static func ==(lhs: Package, rhs: Package) -> Bool {
        return lhs.url == rhs.url && lhs.version == rhs.version
    }
}

extension Package: Hashable {
    public var hashValue: Int {
        return "\(url.absoluteString);\(version.description)".hashValue
    }
}

extension Package: Unboxable {
    public init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "name")
        url = try unboxer.unbox(key: "url")
        
        if let versionData: [String: Int] = try? unboxer.unbox(key: "version")
            , let major: Int = versionData["major"]
            , let minor: Int = versionData["minor"]
            , let patch: Int = versionData["patch"] {
            version = Version(major: major, minor: minor, patch: patch, prefix: nil, suffix: nil)
        } else {
            let majorVersion: Int = try unboxer.unbox(key: "majorVersion")
            version = Version(major: majorVersion)
        }
        
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
        
        if toolsVersion >= Version(major: 4, minor: 2) && !url.isForRemoteRepository {
            return ".package(path: \"\(url.absoluteString)\")"
        }

        return ".package(url: \"\(url.absoluteString)\", from: \"\(version.major).\(version.minor).\(version.patch)\")"
    }
}

internal extension Package {
    struct Pinned {
        let name: String
        let url: URL
        let version: Version
    }
}

extension Package.Pinned: Unboxable {
    init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "package")
        url = try unboxer.unbox(key: "repositoryURL")

        if let legacyVersion: Version = unboxer.unbox(key: "version") {
            version = legacyVersion
        } else {
            version = try unboxer.unbox(keyPath: "state.version")
        }
    }
}
