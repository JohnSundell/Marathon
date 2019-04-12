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

internal class InstallTask: Task, Executable {
    private typealias Error = InstallError

    func execute() throws {
        guard let path = arguments.first else {
            throw Error.missingPath
        }

        let script = try scriptManager.script(atPath: path, allowRemote: true)
        let installPath = makeInstallPath(for: script)

        printer.reportProgress("Compiling script...")
        try script.build(withArguments: ["-c", "release"])
        printer.reportProgress("Installing binary...")
        let installed = try script.install(at: installPath, confirmBeforeOverwriting: !arguments.contains("--force"))

        guard installed else {
            return printer.output("✋  Installation cancelled")
        }

        printer.output("💻  \(path) installed at \(installPath)")
    }

    private func makeInstallPath(for script: Script) -> String {
        if let argument = arguments.element(at: 1) {
            if argument != "--force" && argument != "--verbose" {
                return argument
            }
        }

        return "/usr/local/bin/\(script.name.lowercased())"
    }
}
