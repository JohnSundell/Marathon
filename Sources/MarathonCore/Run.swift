/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

// MARK: - Error

public enum RunError {
    case missingPath
    case failedToRunScript(String)
}

extension RunError: PrintableError {
    public var message: String {
        switch self {
        case .missingPath:
            return "No script path given"
        case .failedToRunScript(_):
            return "Failed to run script"
        }
    }

    public var hint: String? {
        switch self {
        case .missingPath:
            return "Pass the path to a script file to run (for example 'marathon run script.swift')"
        case .failedToRunScript(let message):
            return message
        }
    }
}

// MARK: - Task

internal class RunTask: Task, Executable {
    private typealias Error = RunError

    // MARK: - Executable

    func execute() throws -> String {
        guard let path = firstArgumentAsScriptPath else {
            throw Error.missingPath
        }

        let script = try scriptManager.script(at: path)
        try script.build()

        do {
            return try script.run(in: folder, with: Array(arguments.dropFirst()))
        } catch {
            throw Error.failedToRunScript((error as! Process.Error).message)
        }
    }
}
