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

final class CreateTask: Task, Executable {
    
    private typealias Error = CreateError
    
    private let name: String?
    private let content: String?
    private let options: [Option]
    
    init(arguments: [String], rootFolderPath: String, printer: Printer, options: [Option]) {
        
        self.options = options
        
        let element1 = arguments.element(at: 0)
        let element2 = arguments.element(at: 1)
        
        switch (element1 , element2) {
        case (let value1?, let value2?):
            self.name = value1
            self.content = value2
            super.init(rootFolderPath: rootFolderPath, printer: printer)
        default:
            self.name = arguments.first
            self.content = nil
            super.init(rootFolderPath: rootFolderPath, printer: printer)
        }
    }
    
    func execute() throws {
        guard let name = name else {
            throw Error.missingName
        }
        if file(with: name) != nil {
            let task = EditTask(arguments: [name], rootFolderPath: rootPath, printer: output, options: options)
            return try task.execute()
        }
        try createFile(with: name)
        output.conclusion("🐣  Created script at \(name)")
        try launchIfNeeded(name)
    }
    
    private func file(with name: String) -> File? {
        switch try? File(path: name) {
        case .some(let file):
            return file
        case .none:
            return nil
        }
    }
    
    @discardableResult
    private func createFile(with name: String) throws -> File {
        guard let content = content else {
            return try createFile(with: name, using: "import Foundation\n\n")
        }
        return try createFile(with: name, using: content)
    }
    
    @discardableResult
    private func createFile(with name: String, using content: String) throws -> File {
        switch content.data(using: .utf8) {
        case .some(let data):
            return try perform(FileSystem().createFile(at: name.asScriptPath(), contents: data), orThrow: Error.failedToCreateFile(name))
        case .none:
            throw Error.failedToCreateFile(name)
        }
    }
    
    private var shouldGenerateXcodeProject: Bool {
        return options.contains(.noXcode) == false
    }
    
    private var shouldLaunchEditor: Bool {
        return options.contains(.noOpen) == false
    }
    
    private func launchIfNeeded(_ name: String) throws {
        if shouldLaunchEditor || shouldGenerateXcodeProject {
            let scriptManager = try ScriptManager.assemble(with: rootPath, using: output)
            let script = try scriptManager.script(withName: name, allowRemote: false)
            if shouldGenerateXcodeProject {
                try script.generateXcodeProject()
                _ = try script.editingPath(shouldGenerateXcodeProject)
            }
            if shouldLaunchEditor {
                try script.watch(shouldGenerateXcodeProject)
            }
        }
    }
}
