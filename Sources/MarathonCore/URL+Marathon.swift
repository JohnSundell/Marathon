/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Require

internal extension URL {
    var isForRemoteRepository: Bool {
        return absoluteString.hasSuffix(".git")
    }

    var isForScript: Bool {
        return absoluteString.hasSuffix(".swift")
    }

    var parent: URL? {
        guard let scheme = scheme else {
            return nil
        }

        let schemeWithSuffix = scheme + "://"
        let string = absoluteString

        guard string != schemeWithSuffix else {
            return nil
        }

        let components = string.components(separatedBy: "/")

        guard components.count > 1 else {
            return nil
        }

        let lastComponent: String

        if string.hasSuffix("/") {
            lastComponent = components[components.count - 2] + "/"
        } else {
            lastComponent = components.last.require()
        }

        guard lastComponent != schemeWithSuffix else {
            return nil
        }

        let parentEndIndex = string.index(string.endIndex, offsetBy: -lastComponent.length)
        let parentString = string.substring(to: parentEndIndex)

        guard parentString != schemeWithSuffix else {
            return nil
        }

        return URL(string: parentString).require()
    }
}
