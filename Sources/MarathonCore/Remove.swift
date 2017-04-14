/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum RemoveError {
    case missingIdentifier
}

extension RemoveError: PrintableError {
    public var message: String {
        switch self {
        case .missingIdentifier:
            return "Missing package name or script path to remove data for"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingIdentifier:
            return ["When using 'remove', pass either:\n" +
                   "- The name of a package to remove\n" +
                   "- The path to a script to remove cache data for (including '.swift')"]
        }
    }
}

// MARK: - Task

internal final class RemoveTask: Task, Executable {
    private typealias Error = RemoveError

    func execute() throws {
        if arguments.contains("--all-script-data") || arguments.contains("--all-packages") {
            var deletedObjects: [String] = []

            if arguments.contains("--all-script-data") {
                try scriptManager.removeAllScriptData()
                deletedObjects.append("all script data")
            }

            if arguments.contains("--all-packages") {
                try packageManager.removeAllPackages()
                deletedObjects.append("all packages")
            }

            return printer.output("🗑  Removed \(deletedObjects.joined(separator: " and "))")
        }

        guard let identifier = arguments.first else {
            throw Error.missingIdentifier
        }

        if identifier.hasSuffix(".swift") {
            try scriptManager.removeDataForScript(at: identifier)
            return printer.output("🗑  Removed cache data for script '\(identifier)'")
        }

        let package = try packageManager.removePackage(named: identifier)
        printer.output("🗑  Removed package '\(package.name)'")
    }
}
