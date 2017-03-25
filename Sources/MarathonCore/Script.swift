/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

// MARK: - Error

public enum ScriptError {
    case editingFailed(String)
}

extension ScriptError: PrintableError {
    public var message: String {
        switch self {
        case .editingFailed(let name):
            return "Failed to open script '\(name)' for editing"
        }
    }

    public var hint: String? {
        switch self {
        case .editingFailed(_):
            return "Make sure that it exists and that its file is readable"
        }
    }
}

// MARK: - Script

internal final class Script {
    private typealias Error = ScriptError

    // MARK: - Properties

    let name: String
    let folder: Folder
    var marathonFile: File? { return resolveMarathonfile() }

    private var copyLoopDispatchQueue: DispatchQueue?

    // MARK: - Init

    init(name: String, folder: Folder) {
        self.name = name
        self.folder = folder
    }

    // MARK: - API

    func build() throws {
        try folder.moveToAndPerform(command: "swift build")
    }

    func run(in executionFolder: Folder, with arguments: [String]) throws -> String {
        let scriptPath = folder.path + ".build/debug/" + name
        let command = scriptPath + " " + arguments.joined(separator: " ")
        return try executionFolder.moveToAndPerform(command: command)
    }

    func edit(arguments: [String], open: Bool) throws {
        do {
            let path = try editingPath(from: arguments)

            if open {
                let relativePath = path.replacingOccurrences(of: folder.path, with: "")
                print("✏️  Opening \(relativePath)")

                try Process().launchBash(withCommand: "open \(path)")

                if path.hasSuffix(".xcodeproj/") {
                    print("\nℹ️  Marathon will keep running, in order to commit any changes you make in Xcode back to the original script file")
                    print("   Press any key once you're done")

                    startCopyLoop()
                    _ = FileHandle.standardInput.availableData
                    try copyChangesToSymlinkedFile()
                }
            }
        } catch {
            throw Error.editingFailed(name)
        }
    }

    // MARK: - Private

    private func editingPath(from arguments: [String]) throws -> String {
        guard !arguments.contains("--no-xcode") else {
            return try expandSymlink()
        }

        return try generateXcodeProject().path
    }

    private func generateXcodeProject() throws -> Folder {
        try folder.moveToAndPerform(command: "swift package generate-xcodeproj")
        return try folder.subfolder(named: name + ".xcodeproj")
    }

    private func expandSymlink() throws -> String {
        return try folder.moveToAndPerform(command: "readlink OriginalFile")
    }

    private func resolveMarathonfile() -> File? {
        do {
            let scriptFile = try File(path: expandSymlink())
            return try scriptFile.parent?.file(named: "Marathonfile")
        } catch {
            return nil
        }
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
}
