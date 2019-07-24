/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum AddError {
    case missingIdentifier
    case invalidURL(String)
}

extension AddError: PrintableError {
    public var message: String {
        switch self {
        case .missingIdentifier:
            return "No path or URL given"
        case .invalidURL(let string):
            return "Cannot add package with an invalid URL '\(string)'"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingIdentifier:
            return ["When using 'add', pass either:\n" +
                   "- The git URL of a remote package to add (for example 'marathon add git@github.com:JohnSundell/Files.git')\n" +
                   "- The path of a local package to add (for example 'marathon add packages/myPackage')"]
        case .invalidURL:
            return []
        }
    }
}

// MARK: - Task

internal final class AddTask: Task, Executable {
    private typealias Error = AddError

    // MARK: - Executable

    func execute() throws {
        guard let identifier = arguments.first else {
            throw Error.missingIdentifier
        }

        guard let url = URL(string: identifier) else {
            throw Error.invalidURL(identifier)
        }

        let package = try packageManager.addPackage(at: url)
        printer.output("📦  \(package.name) added")
    }
}
