/**
 *  Marathon
 *  Copyright (c) Krzysztof Kapitan 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

final class URLTransformer {
    static func transform(_ url: URL) -> URL {
        guard url.isGithubURL else { return url }
        return url.rawGithubUrl ?? url
    }
}

fileprivate extension URL {
    var isGithubURL: Bool {
        return host == "github.com"
    }

    var rawGithubUrl: URL? {
        let base = "https://raw.githubusercontent.com"

        let urlString = pathComponents
            .filter { $0 != "blob" && $0 != "/" }
            .reduce(base) { "\($0)/\($1)" }

        return URL(string: urlString)
    }
}
