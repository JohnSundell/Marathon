/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import ShellOut
import Require
#if os(Linux)
    import Dispatch
#endif

// MARK: - Error

public enum ScriptError {
    case editingFailed(String)
    case buildFailed([String], missingPackage: String?)
    case installFailed(String)
}

extension ScriptError: PrintableError {
    public var message: String {
        switch self {
        case .editingFailed(let name):
            return "Failed to open script '\(name)' for editing"
        case .buildFailed(_, _):
            return "Failed to compile script"
        case .installFailed(_):
            return "Failed to install script"
        }
    }

    public var hints: [String] {
        switch self {
        case .editingFailed(_):
            return ["Make sure that it exists and that its file is readable"]
        case .buildFailed(let errors, let missingPackage):
            guard !errors.isEmpty else {
                return []
            }

            let separator = "\n- "
            var hints = ["The following error(s) occured:" + separator + errors.joined(separator: separator)]

            if let missingPackage = missingPackage {
                hints.append("You can add \(missingPackage) to Marathon using 'marathon add <url-to-\(missingPackage)>'")
            }

            return hints
        case .installFailed(let path):
            return ["Make sure that you have write permissions to the path '\(path)' and that all parent folders exist"]
        }
    }
}

// MARK: - Script

internal final class Script {
    private typealias Error = ScriptError

    // MARK: - Properties

    let name: String
    let folder: Folder

    private let printer: Printer
    private var copyLoopDispatchQueue: DispatchQueue?

    // MARK: - Init

    init(name: String, folder: Folder, printer: Printer) {
        self.name = name
        self.folder = folder
        self.printer = printer
    }

    // MARK: - API

    func build(withArguments arguments: [String] = []) throws {
        do {
            let command = "swift build --enable-prefetching " + arguments.joined(separator: " ")
            try folder.moveToAndPerform(command: command, printer: printer)
        } catch {
            throw formatBuildError(error as! ShellOutError)
        }
    }

    func run(in executionFolder: Folder, with arguments: [String]) throws -> String {
        let scriptPath = folder.path + ".build/debug/" + name
        let command = scriptPath + " " + arguments.joined(separator: " ")
        return try executionFolder.moveToAndPerform(command: command, printer: printer)
    }

    func install(at path: String, confirmBeforeOverwriting: Bool) throws -> Bool {
        do {
            var pathComponents = path.components(separatedBy: "/")
            let installName = pathComponents.removeLast()
            let parentFolder = try Folder(path: pathComponents.joined(separator: "/"))
            let path = "\(parentFolder.path)\(installName)"

            if confirmBeforeOverwriting {
                if (try? parentFolder.file(named: installName)) != nil {
                    printer.output("⚠️  A binary already exists at \(path)")
                    printer.output("❓  Are you sure you want to overwrite it? (Type 'Y' to confirm)")

                    let input = readLine()?.lowercased()

                    guard input == "y" else {
                        return false
                    }
                }
            }

            let buildFolder = try folder.subfolder(atPath: ".build/release")
            try buildFolder.moveToAndPerform(command: "cp -f \(name) \(path)", printer: printer)

            return true
        } catch {
            throw Error.installFailed(path)
        }
    }

    func edit(arguments: [String], open: Bool) throws {
        do {
            let path = try editingPath(from: arguments)

            if open {
                let relativePath = path.replacingOccurrences(of: folder.path, with: "")
                printer.output("✏️  Opening \(relativePath)")

                try shellOut(to: "open \"\(path)\"", printer: printer)

                if path.hasSuffix(".xcodeproj/") {
                    printer.output("\nℹ️  Marathon will keep running, in order to commit any changes you make in Xcode back to the original script file")
                    printer.output("   Press the return key once you're done")

                    startCopyLoop()
                    _ = FileHandle.standardInput.availableData
                    try copyChangesToSymlinkedFile()
                }
            }
        } catch {
            throw Error.editingFailed(name)
        }
    }

    func resolveMarathonFile() throws -> MarathonFile? {
        let scriptFile = try File(path: expandSymlink())

        guard let parentFolder = scriptFile.parent else {
            return nil
        }

        guard let file = try? parentFolder.file(named: "Marathonfile") else {
            return nil
        }

        return try MarathonFile(file: file)
    }

    // MARK: - Private

    private func editingPath(from arguments: [String]) throws -> String {
        guard !arguments.contains("--no-xcode") else {
            return try expandSymlink()
        }

        return try generateXcodeProject().path
    }

    private func generateXcodeProject() throws -> Folder {
        try folder.moveToAndPerform(command: "swift package generate-xcodeproj", printer: printer)
        return try folder.subfolder(named: name + ".xcodeproj")
    }

    private func expandSymlink() throws -> String {
        return try folder.moveToAndPerform(command: "readlink OriginalFile", printer: printer)
    }

    private func startCopyLoop() {
        let dispatchQueue: DispatchQueue

        if let existingQueue = copyLoopDispatchQueue {
            dispatchQueue = existingQueue
        } else {
            let newQueue = DispatchQueue(label: "com.marathon.fileCopyLoop")
            copyLoopDispatchQueue = newQueue
            dispatchQueue = newQueue
        }

        dispatchQueue.asyncAfter(deadline: .now() + .seconds(3)) { [weak self] in
            try? self?.copyChangesToSymlinkedFile()
            self?.startCopyLoop()
        }
    }

    private func copyChangesToSymlinkedFile() throws {
        let data = try folder.file(atPath: "Sources/main.swift").read()
        try File(path: expandSymlink()).write(data: data)
    }

    private func formatBuildError(_ error: ShellOutError) -> Error {
        var messages = [String]()

        for outputComponent in error.output.components(separatedBy: "\n") {
            let lineComponents = outputComponent.components(separatedBy: folder.path + "Sources/main.swift:")

            guard lineComponents.count > 1 else {
                continue
            }

            let message = lineComponents.last.require().replacingOccurrences(of: " error:", with: "")
            messages.append(message)

            if let range = message.range(of: "'[A-Za-z]+'", options: .regularExpression), message.contains("no such module") {
                let missingPackage = message[range].replacingOccurrences(of: "'", with: "")
                return Error.buildFailed(messages, missingPackage: missingPackage)
            }
        }

        return Error.buildFailed(messages, missingPackage: nil)
    }
}
