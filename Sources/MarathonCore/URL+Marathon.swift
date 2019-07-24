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

        let parentEndIndex = string.index(string.endIndex, offsetBy: -lastComponent.count)
        let parentString = String(string[..<parentEndIndex])

        guard parentString != schemeWithSuffix else {
            return nil
        }

        return URL(string: parentString).require()
    }

    func transformIfNeeded() -> URL {
        guard isGitHubURL else {
            return self
        }

        return rawGitHubURL ?? self
    }

    private var isGitHubURL: Bool {
        return host == "github.com"
    }

    private var rawGitHubURL: URL? {
        let base = "https://raw.githubusercontent.com"

        let urlString = pathComponents
            .filter { $0 != "blob" && $0 != "/" }
            .reduce(base) { "\($0)/\($1)" }

        return URL(string: urlString)
    }
}
