/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum AddError {
    case missingIdentifier
    case invalidURL(String)
}

extension AddError: PrintableError {
    public var message: String {
        switch self {
        case .missingIdentifier:
            return "No path or URL given"
        case .invalidURL(let string):
            return "Cannot add package with an invalid URL '\(string)'"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingIdentifier:
            return ["When using 'add', pass either:\n" +
                   "- The git URL of a remote package to add (for example 'marathon add git@github.com:JohnSundell/Files.git')\n" +
                   "- The path of a local package to add (for example 'marathon add packages/myPackage')"]
        case .invalidURL:
            return []
        }
    }
}

// MARK: - Task

final class AddTask: Task, Executable {
  
    private typealias Error = AddError
    
    private let name: String?
    private let options: [Option]
    
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
            try continueExecution(name)
        } else {
            throw Error.missingIdentifier
        }
    }
    
    private func continueExecution(_ name: String) throws {
        switch URL(string: name) {
        case .some(let url):
            try continueExecution(url)
        case .none:
            throw Error.invalidURL(name)
        }
        
    }
    
    private func continueExecution(_ url: URL) throws {
        let packageManager = try PackageManager.assemble(with: rootPath, using: output)
        let package = try packageManager.addPackage(at: url)
        let feedback = "📦  \(package.name) added"
        output.conclusion(feedback)
    }
}
