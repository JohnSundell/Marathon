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

internal final class CreateTask: Task, Executable {
    private typealias Error = CreateError
    
    private var shouldOpen: Bool {
        return !argumentsContainNoOpenFlag
    }
    
    func execute() throws {
        guard let path = arguments.first?.asScriptPath() else {
            throw Error.missingName
        }
        
        if arguments.contains("--tests") {
            if let scriptFile = try? FileSystem().currentFolder.file(atPath: path),
                let script = try? scriptManager.script(at: scriptFile.path) {
                try createScriptTests(for: script)
                try beginEditing(script, if: shouldOpen)
            } else {
                let file = try createScript(at: path)
                let script = try scriptManager.script(at: file.path)
                try createScriptTests(for: script)
                try beginEditing(script, if: shouldOpen)
            }
        } else {
            let file = try createScript(at: path)
            try beginEditing(file, if: shouldOpen)
        }
    }
    
    private func createScript(at path: String) throws -> File {
        guard let data = makeScriptContent().data(using: .utf8) else {
            throw Error.failedToCreateFile(path)
        }
        
        let file = try perform(FileSystem().createFile(at: path, contents: data),
                               orThrow: Error.failedToCreateFile(path))
        
        printer.output("🐣  Created script at \(path)")
        
        return file
    }
    
    @discardableResult private func createScriptTests(for script: Script) throws -> File {
        guard let testPath = arguments.first?.asTestScriptPath() else {
            throw Error.missingName
        }
        
        guard let data = makeTestScriptContent(for: script).data(using: .utf8) else {
            throw Error.failedToCreateFile(testPath)
        }
        
        let testFile = try perform(FileSystem().createFile(at: testPath, contents: data),
                                   orThrow: Error.failedToCreateFile(testPath))
        
        try scriptManager.addTest(file: testFile, to: script)
        
        printer.output("✅  Created tests at \(testPath)")
        
        return testFile
    }
    
    private func beginEditing(_ file: File, if open: Bool) throws {
        guard open else { return }
        let script = try scriptManager.script(at: file.path)
        try script.edit(arguments: arguments, open: true)
    }
    
    private func beginEditing(_ script: Script, if open: Bool) throws {
        guard open else { return }
        try script.edit(arguments: arguments, open: true)
    }

    private func makeScriptContent() -> String {
        let defaultContent = "import Foundation\n\n"

        guard let argument = arguments.element(at: 1) else {
            return defaultContent
        }

        guard !argument.hasPrefix("-") else {
            return defaultContent
        }

        return argument
    }
    
    private func makeTestScriptContent(for script: Script) -> String {
        let defaultContent =
            "import XCTest\n" +
            "@testable import \(script.name)\n\n" +
            "class \(script.name)Tests: XCTestCase {\n" +
            "\tfunc testExample() {\n" +
            "\t\tXCTAssert(true)\n" +
            "\t}\n\n" +
            "\tstatic var allTests = [\n" +
            "\t\t(\"testExample\", testExample),\n" +
            "\t]\n" +
            "}\n"
        
        return defaultContent
    }
    
}
