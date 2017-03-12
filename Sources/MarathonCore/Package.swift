/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Unbox

internal struct Package {
    let name: String
    let url: URL
    var majorVersion: Int
}

extension Package {
    var dependencyString: String {
        return ".Package(url: \"\(url.absoluteString)\", majorVersion: \(majorVersion))"
    }
}

extension Package: Equatable {
    static func ==(lhs: Package, rhs: Package) -> Bool {
        return lhs.url == rhs.url && lhs.majorVersion == rhs.majorVersion
    }
}

extension Package: Unboxable {
    init(unboxer: Unboxer) throws {
        name = try unboxer.unbox(key: "name")
        url = try unboxer.unbox(key: "url")
        majorVersion = try unboxer.unbox(key: "majorVersion")
    }
}
