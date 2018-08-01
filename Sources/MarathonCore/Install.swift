/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum InstallError {
    case missingPath
}

extension InstallError: PrintableError {
    public var message: String {
        switch self {
        case .missingPath:
            return "No script path given"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingPath:
            return ["Pass the path to a script file to install (for example 'marathon install script.swift')"]
        }
    }
}

// MARK: - Task

final class InstallTask: Task, Executable {
    
    private typealias Error = InstallError

    private var shouldForce: Bool {
        return options.contains(.force) == true
    }
    
    private var printVerbose: Bool {
        return options.contains(.verbose) == true
    }
    
    private let name: String?
    private let installPath: String
    private let options: [Option]
    
    init(arguments: [String], rootFolderPath: String, printer: Printer, options: [Option]) {
        self.options = options
        let element1 = arguments.element(at: 0)
        let element2 = arguments.element(at: 1)
        switch (element1 , element2) {
        case (let value1?, let value2?):
            self.name = value1
            self.installPath = value2
            super.init(rootFolderPath: rootFolderPath, printer: printer)
        default:
            self.name = arguments.first
            let path = self.name ?? ""
            self.installPath = "/usr/local/bin/\(path.lowercased())"
            super.init(rootFolderPath: rootFolderPath, printer: printer)
        }
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
        
        output.progress("Compiling script...")
        
        #if os(Linux)
        try script.build(for: .release(environment: .linux))
        #else
        try script.build(for: .release(environment: .unspecified))
        #endif
        
        output.progress("Installing binary...")
        
        let installed = try script.install(at: installPath, confirmBeforeOverwriting: !shouldForce)
        
        guard installed else {
            return output.conclusion("✋  Installation cancelled")
        }
        
        output.conclusion("💻  \(name) installed at \(installPath)")
    }
}
