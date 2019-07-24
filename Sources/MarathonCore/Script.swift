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
    case watchingFailed(String)
    case buildFailed([String], missingPackage: String?)
    case installFailed(String)
}

extension ScriptError: PrintableError {
    public var message: String {
        switch self {
        case .editingFailed(let name):
            return "Failed to open script '\(name)' for editing"
        case .buildFailed:
            return "Failed to compile script"
        case .installFailed:
            return "Failed to install script"
        case .watchingFailed(let name):
            return "Failed to start watcher for \(name)"
        }
    }

    public var hints: [String] {
        switch self {
        case .editingFailed:
            return ["Make sure that it exists and that its file is readable"]
        case .watchingFailed:
            return ["Check the error message for more information"]
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

public final class Script {
    private typealias Error = ScriptError

    // MARK: - Properties

    public let name: String
    public let folder: Folder

    private let printer: Printer
    private var copyLoopDispatchQueue: DispatchQueue?
    private var localPath: String { return "Sources/\(name)/main.swift"  }

    // MARK: - Init

    init(name: String, folder: Folder, printer: Printer) {
        self.name = name
        self.folder = folder
        self.printer = printer
    }

    // MARK: - API

    public func build(withArguments arguments: [String] = []) throws {
        do {
            let command = "build -C \(folder.path) " + arguments.joined(separator: " ")
            try shellOutToSwiftCommand(command, in: folder, printer: printer)
        } catch {
            throw formatBuildError(error as! ShellOutError)
        }
    }

    public func run(in executionFolder: Folder, with arguments: [String]) throws -> String {
        let scriptPath = folder.path + ".build/debug/" + name
        var command = scriptPath

        if !arguments.isEmpty {
            command += " \"" + arguments.joined(separator: "\" \"") + "\""
        }

        return try executionFolder.moveToAndPerform(command: command, printer: printer)
    }

    public func install(at path: String, confirmBeforeOverwriting: Bool) throws -> Bool {
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

    @discardableResult
    public func setupForEdit(arguments: [String]) throws -> String {
        do {
            if !arguments.contains("--no-xcode") {
                try generateXcodeProject()
            }

            return try editingPath(from: arguments)
        } catch {
            throw Error.editingFailed(name)
        }
    }

    public func watch(arguments: [String]) throws {
        do {
            let path = try editingPath(from: arguments)
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
        } catch {
            throw Error.watchingFailed(name)
        }
    }

    func resolveMarathonFile(fileName: String) throws -> MarathonFile? {
        let scriptFile = try File(path: expandSymlink())

        guard let parentFolder = scriptFile.parent else {
            return nil
        }

        guard let file = try? parentFolder.file(named: fileName) else {
            return nil
        }

        return try MarathonFile(file: file)
    }

    // MARK: - Private

    private func editingPath(from arguments: [String]) throws -> String {
        guard !arguments.contains("--no-xcode") else {
            return try expandSymlink()
        }

        return try folder.subfolder(named: name + ".xcodeproj").path
    }

    private func generateXcodeProject() throws {
        try shellOutToSwiftCommand("package generate-xcodeproj", in: folder, printer: printer)
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
        let data = try folder.file(atPath: localPath).read()
        try File(path: expandSymlink()).write(data: data)
    }

    private func formatBuildError(_ error: ShellOutError) -> Error {
        var messages = [String]()

        for outputComponent in error.output.components(separatedBy: "\n") {
            let lineComponents = outputComponent.components(separatedBy: folder.path + "\(localPath):")

            guard lineComponents.count > 1 else {
                continue
            }

            let message = lineComponents.last.require().replacingOccurrences(of: " error:", with: "")
            messages.append(message)

            if let range = message.range(of: "'[A-Za-z]+'", options: .regularExpression), message.contains("no such module") {
                let missingPackage = String(message[range]).replacingOccurrences(of: "'", with: "")
                return Error.buildFailed(messages, missingPackage: missingPackage)
            }
        }

        return Error.buildFailed(messages, missingPackage: nil)
    }
}
