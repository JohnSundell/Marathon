/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum CreateError {
    case missingName
    case failedToCreateFile(String)
}

extension CreateError: PrintableError {
    public var message: String {
        switch self {
        case .missingName:
            return "No script name given"
        case .failedToCreateFile(let name):
            return "Failed to create script file named '\(name)'"
        }
    }

    public var hint: String? {
        switch self {
        case .missingName:
            return "Pass the name of a script file to create (for example 'marathon create myScript')"
        case .failedToCreateFile:
            return "Make sure you have write permissions to the current folder"
        }
    }
}

// MARK: - Task

internal final class CreateTask: Task, Executable {
    private typealias Error = CreateError

    func execute() throws -> String {
        guard let name = firstArgumentAsScriptPath else {
            throw Error.missingName
        }

        let script = arguments.element(at: 1) ?? "import Foundation\n\n"
        let file = try perform(folder.createFile(named: name, contents: script.data(using: .utf8)!),
                               orThrow: Error.failedToCreateFile(name))

        var output = "🐣  Created script \(name)"

        if !argumentsContainNoOpenFlag {
            let editingPath = try scriptManager.script(at: file.path).edit(arguments: arguments, open: true)
            output.append("\n✏️  Opening \(editingPath)")
        }

        return output
    }
}
