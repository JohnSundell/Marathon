/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public protocol PrintableError: Error, Equatable, CustomStringConvertible {
    var message: String { get }
    var hint: String? { get }
}

public extension PrintableError {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.message == rhs.message && lhs.hint == rhs.hint
    }

    var description: String {
        var description = "💥  \(message)"

        if let hint = hint {
            description.append("\n" + hint.withIndentedNewLines(prefix: "👉  "))
        }

        return description
    }
}
