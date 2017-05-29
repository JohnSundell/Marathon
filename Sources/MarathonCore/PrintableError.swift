/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public protocol PrintableError: Error, Equatable, CustomStringConvertible {
    var message: String { get }
    var hints: [String] { get }
}

public extension PrintableError {
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return lhs.message == rhs.message && lhs.hints == rhs.hints
    }

    var description: String {
        var description = "💥  \(message)"

        if !hints.isEmpty {
            hints.forEach { description.append("\n" + $0.withIndentedNewLines(prefix: "👉  ")) }
        }

        return description
    }
}
