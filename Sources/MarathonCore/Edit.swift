/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

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

final class EditTask: Task, Executable {
    
    private typealias Error = EditError
    
    private let name: String?
    private let options: [Option]
    
    private var shouldGenerateXcodeProject: Bool {
        return options.contains(.noXcode) == false
    }
    
    private var shouldLaunchEditor: Bool {
        return options.contains(.noOpen) == false
    }
    
    init(arguments: [String], rootFolderPath: String, printer: Printer, options: [Option]) {
        self.options = options
        switch arguments.first {
        case .some(let name):
            self.name = name
        case .none:
            self.name = nil
        }
        super.init(rootFolderPath: rootFolderPath, printer: printer)
    }
    
    func execute() throws {
        if let name = name {
            try launchIfNeeded(name.asScriptPath())
        } else {
            throw Error.missingPath
        }
    }
    
    private func launchIfNeeded(_ name: String) throws {
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
