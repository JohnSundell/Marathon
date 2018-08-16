/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import ShellOut
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

final class RunTask: Task, Executable {
    
    private typealias Error = RunError
    
    private let name: String?
    private let arguments: [String]
    
    init(arguments: [String], rootFolderPath: String, printer: Printer) {
        switch arguments.first {
        case .some(let name):
            self.name = name
            self.arguments = Array(arguments.dropFirst())
        case .none:
            self.name = nil
            self.arguments = arguments
        }
        super.init(rootFolderPath: rootFolderPath, printer: printer)
    }
    
    func execute() throws {
        if let name = name {
            try continueExecution(name)
        } else {
            throw Error.missingPath
        }
    }
    
    private func continueExecution(_ name: String) throws {
        let scriptManager = try ScriptManager.assemble(with: rootPath, using: output)
        let script = try scriptManager.script(withName: name, allowRemote: true)
        try script.build(for: .debug(environment: .unspecified))
        do {
            let feedback = try script.run(in: FileSystem().currentFolder, with: arguments)
            output.conclusion(feedback)
        } catch {
            let error = (error as? ShellOutError).require()
            throw Error.failedToRunScript(error.message)
        }
    }
}
