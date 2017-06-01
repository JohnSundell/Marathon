/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Error

public enum TestError {
    case missingPath
}

extension TestError: PrintableError {
    public var message: String {
        switch self {
        case .missingPath:
            return "No script name/path given"
        }
    }
    
    public var hints: [String] {
        switch self {
        case .missingPath:
            return ["Pass the name/path of a script file to test (for example 'marathon test myScript')"]
        }
    }
}

// MARK: - Task

internal final class TestTask: Task, Executable {
    private typealias Error = TestError

    // MARK: - Executable
    
    func execute() throws {
        guard let path = arguments.first?.asScriptPath() else {
            throw Error.missingPath
        }
        
        let script = try scriptManager.script(at: path)
        try script.test(arguments: arguments, open: !argumentsContainNoOpenFlag)
    }
}
