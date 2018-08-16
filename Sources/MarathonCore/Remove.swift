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

final class RemoveTask: Task, Executable {
    
    private typealias Error = RemoveError
  
    private let identifier: String?
    private let options: [Option]
    
    init(arguments: [String], rootFolderPath: String, printer: Printer, options: [Option]) {
        self.options = options
        switch arguments.first {
        case .some(let identifier):
            self.identifier = identifier
        case .none:
            self.identifier = nil
        }
        super.init(rootFolderPath: rootFolderPath, printer: printer)
    }
    
    func execute() throws {
        let scriptManager = try ScriptManager.assemble(with: rootPath, using: output)
        if let feedback = try removeData(scriptManager) {
            return output.conclusion(feedback)
        }
        if let identifier = identifier {
            try continueExecution(identifier, scriptManager)
        } else {
            throw Error.missingIdentifier
        }
    }
    
    private func continueExecution(_ identifier: String, _ scriptManager: ScriptManager) throws {
        if identifier.hasSuffix(".swift") {
            let feedback = try removeScript(identifier, scriptManager)
            return output.conclusion(feedback)
        }
        
        let feedback = try removePackage(identifier, scriptManager)
        output.conclusion(feedback)
    }
    
    private var shouldRemoveAllScriptData: Bool {
        return options.contains(.allScriptData) == true
    }
    
    private var shouldRemoveAllPackages: Bool {
        return options.contains(.allPackages) == true
    }
    
    private func removeData(_ scriptManager: ScriptManager) throws -> String? {
        if shouldRemoveAllScriptData || shouldRemoveAllPackages {
            var deletedObjects: [String] = []
            
            if shouldRemoveAllScriptData {
                try scriptManager.removeAllScriptData()
                deletedObjects.append("all script data")
            }
            
            if shouldRemoveAllPackages {
                try scriptManager.removeAllPackages()
                deletedObjects.append("all packages")
            }
            return "🗑  Removed \(deletedObjects.joined(separator: " and "))"
        }
        return nil
    }
    
    private func removeScript(_ name: String, _ scriptManager: ScriptManager) throws -> String {
        try scriptManager.removeDataForScript(at: name)
        return "🗑  Removed cache data for script '\(name)'"
    }
    
    private func removePackage(_ name: String, _ scriptManager: ScriptManager) throws -> String {
        let package = try scriptManager.removePackage(with: name)
        return "🗑  Removed package '\(package.name)'"
    }
}
