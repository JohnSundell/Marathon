/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

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

    public var hints: [String] {
        switch self {
        case .missingName:
            return ["Pass the name of a script file to create (for example 'marathon create myScript')"]
        case .failedToCreateFile:
            return ["Make sure you have write permissions to the current folder"]
        }
    }
}

// MARK: - Task

internal final class CreateTask: Task, Executable {
    private typealias Error = CreateError

    func execute() throws {
        guard let path = arguments.first?.asScriptPath() else {
            throw Error.missingName
        }

        guard (try? File(path: path)) == nil else {
            let editTask = EditTask(
                folder: folder,
                arguments: arguments,
                scriptManager: scriptManager,
                packageManager: packageManager,
                printer: printer
            )

            return try editTask.execute()
        }

        guard let data = makeScriptContent().data(using: .utf8) else {
            throw Error.failedToCreateFile(path)
        }

        let file = try perform(FileSystem().createFile(at: path, contents: data),
                               orThrow: Error.failedToCreateFile(path))

        printer.output("🐣  Created script at \(path)")

        if !argumentsContainNoOpenFlag {
            let script = try scriptManager.script(atPath: file.path, allowRemote: false)
            try script.setupForEdit(arguments: arguments)
            try script.watch(arguments: arguments)
        }
    }

    private func makeScriptContent() -> String {
        let defaultContent = "import Foundation\n\n"

        guard let argument = arguments.element(at: 1) else {
            return defaultContent
        }

        guard !argument.hasPrefix("-") else {
            return defaultContent
        }

        return argument
    }
}
