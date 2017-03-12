/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal extension String {
    var length: String.IndexDistance {
        return distance(from: startIndex, to: endIndex)
    }

    var dashesWithMatchingLength: String {
        return String(repeating: "-", count: length)
    }

    func withIndentedNewLines(prefix: String) -> String {
        var indentedString = ""

        for (index, line) in components(separatedBy: .newlines).enumerated() {
            let linePrefix = (index == 0 ? prefix : "\n   ")
            indentedString.append(linePrefix + line)
        }

        return indentedString
    }
}
