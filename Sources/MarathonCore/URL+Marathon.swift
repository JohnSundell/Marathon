/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Require

internal extension Marathon where Base == URL {
    var isForRemoteRepository: Bool {
        return base.absoluteString.hasSuffix(".git")
    }

    var isForScript: Bool {
        return base.absoluteString.hasSuffix(".swift")
    }

    var parent: URL? {
        guard let scheme = base.scheme else {
            return nil
        }

        let schemeWithSuffix = scheme + "://"
        let string = base.absoluteString

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

        let parentEndIndex = string.index(string.endIndex, offsetBy: -lastComponent.mt.length)
        let parentString = string.substring(to: parentEndIndex)

        guard parentString != schemeWithSuffix else {
            return nil
        }

        return URL(string: parentString).require()
    }

    func transformIfNeeded() -> URL {
        guard isGitHubURL else {
            return base.self
        }

        return rawGitHubURL ?? base.self
    }

    private var isGitHubURL: Bool {
        return base.host == "github.com"
    }

    private var rawGitHubURL: URL? {
        let baseURLString = "https://raw.githubusercontent.com"

        let urlString = base.pathComponents
            .filter { $0 != "blob" && $0 != "/" }
            .reduce(baseURLString) { "\($0)/\($1)" }
        
        return URL(string: urlString)
    }
}
