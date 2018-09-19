/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum EditError {
    case missingPath
}

extension EditError: PrintableError {
    public var message: String {
        switch self {
        case .missingPath:
            return "No script name/path given"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingPath:
            return ["Pass the name/path of a script file to edit (for example 'marathon edit myScript')"]
        }
    }
}

// MARK: - Task

internal final class EditTask: Task, Executable {
    private typealias Error = EditError

    // MARK: - Executable

    func execute() throws {
        guard let path = arguments.first?.asScriptPath() else {
            throw Error.missingPath
        }

        let script = try scriptManager.script(atPath: path, allowRemote: false)
        try script.setupForEdit(arguments: arguments)
        if !argumentsContainNoOpenFlag {
            try script.watch(arguments: arguments)
        }
    }
}
