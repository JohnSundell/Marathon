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
    case failedToCompileScript([String], String?)
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
        case .failedToCompileScript(let errors, _):
            guard !errors.isEmpty else {
                return nil
            }

            let separator = "\n- "
            return "The following error(s) occured:" + separator + errors.joined(separator: separator)
        case .failedToRunScript(let message):
            return message
        }
    }

    public var nextAction: String? {
        switch self {
        case .failedToCompileScript(_, let missingModule):
            if let missingModule = missingModule {
                return "You can add \(missingModule) to Marathon using 'marathon add <url-to-\(missingModule)>'"
            }
            return nil
        default:
            return nil
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

    // MARK: - Private

    private func formatCompileError(_ error: Process.Error, for script: Script) -> Error {
        var messages = [String]()
        var missingModule: String?

        for outputComponent in error.output.components(separatedBy: "\n") {
            let lineComponents = outputComponent.components(separatedBy: script.folder.path + "Sources/main.swift:")

            guard lineComponents.count > 1 else {
                continue
            }

            if let message = lineComponents.last?.replacingOccurrences(of: " error:", with: "") {
                if message.contains("no such module") {
                    if let range = message.range(of: "'[A-Za-z]+'", options: .regularExpression) {
                        missingModule = message[range].replacingOccurrences(of: "'", with: "")
                    }
                }
                messages.append(message)
            }
        }

        return Error.failedToCompileScript(messages, missingModule)
    }
}
