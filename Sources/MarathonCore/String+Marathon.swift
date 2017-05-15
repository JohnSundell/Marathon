/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal extension Marathon where Base == String {
    var length: String.IndexDistance {
        return base.distance(from: base.startIndex, to: base.endIndex)
    }

    var dashesWithMatchingLength: String {
        return String(repeating: "-", count: length)
    }

    func withIndentedNewLines(prefix: String) -> String {
        var indentedString = ""

        for (index, line) in base.components(separatedBy: .newlines).enumerated() {
            let linePrefix = (index == 0 ? prefix : "\n   ")
            indentedString.append(linePrefix + line)
        }

        return indentedString
    }
}
