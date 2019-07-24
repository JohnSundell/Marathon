/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import ShellOut

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
        case .failedToRunScript:
            return "Failed to run script"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingPath:
            return ["Pass the path to a script file to run (for example 'marathon run script.swift')"]
        case .failedToRunScript(let message):
            return [message]
        }
    }
}

// MARK: - Task

internal class RunTask: Task, Executable {
    private typealias Error = RunError

    // MARK: - Executable

    func execute() throws {
        guard let path = arguments.first else {
            throw Error.missingPath
        }

        let script = try scriptManager.script(atPath: path, allowRemote: true)
        try script.build()

        do {
            let output = try script.run(in: folder, with: Array(arguments.dropFirst()))
            printer.output(output)
        } catch {
            throw Error.failedToRunScript((error as! ShellOutError).message)
        }
    }
}
