/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

// MARK: - Error

public enum ScriptManagerError {
    case scriptNotFound(String)
    case failedToCreatePackageFile(Folder)
    case failedToAddDependencyScript(String)
    case failedToRemoveScriptFolder(Folder)
}

extension ScriptManagerError: PrintableError {
    public var message: String {
        switch self {
        case .scriptNotFound(let path):
            return "Could not find a Swift script at '\(path)'"
        case .failedToCreatePackageFile(_):
            return "Failed to create a Package.swift file for the script"
        case .failedToAddDependencyScript(let path):
            return "Failed to add the dependency script at '\(path)'"
        case .failedToRemoveScriptFolder(_):
            return "Failed to remove script folder"
        }
    }

    public var hints: [String] {
        switch self {
        case .scriptNotFound(_):
            return ["Please check that the path is valid and try again"]
        case .failedToCreatePackageFile(let folder),
             .failedToRemoveScriptFolder(let folder):
            return ["Make sure you have write permissions to the folder '\(folder.path)'"]
        case .failedToAddDependencyScript(_):
            return ["Make sure that the file exists and is readable"]
        }
    }
}

// MARK: - ScriptManager

internal final class ScriptManager {
    private typealias Error = ScriptManagerError

    var managedScriptPaths: [String] { return makeManagedScriptPathList() }

    private let folder: Folder
    private let packageManager: PackageManager
    private let print: Printer

    // MARK: - Init

    init(folder: Folder, packageManager: PackageManager, printer: @escaping Printer) {
        self.folder = folder
        self.packageManager = packageManager
        self.print = printer
    }

    // MARK: - API

    func script(at path: String, usingPrinter printer: @escaping Printer) throws -> Script {
        let file = try perform(File(path: path), orThrow: Error.scriptNotFound(path))
        let identifier = scriptIdentifier(from: file.path)
        let name = identifier.components(separatedBy: "-").last!.capitalized
        let folder = try createFolderIfNeededForScript(withIdentifier: identifier, file: file)
        let script = Script(name: name, folder: folder, printer: printer)

        if let marathonFile = try script.resolveMarathonFile() {
            try packageManager.addPackages(fromMarathonFile: marathonFile)
            try addDependencyScripts(fromMarathonFile: marathonFile, toFolder: folder)
        }

        do {
            let packageFile = try folder.createFile(named: "Package.swift")
            try packageFile.write(string: packageManager.makePackageDescription(for: script))
        } catch {
            throw Error.failedToCreatePackageFile(folder)
        }

        return script
    }

    func removeDataForScript(at path: String) throws {
        let identifier = scriptIdentifier(from: path)

        guard let folder = folderForScript(withIdentifier: identifier) else {
            return
        }

        try perform(folder.delete(), orThrow: Error.failedToRemoveScriptFolder(folder))
    }

    func removeAllScriptData() throws {
        for path in managedScriptPaths {
            try removeDataForScript(at: path)
        }
    }

    // MARK: - Private

    private func scriptIdentifier(from path: String) -> String {
        let pathExcludingExtension = path.components(separatedBy: ".swift").first!
        return pathExcludingExtension.replacingOccurrences(of: "/", with: "-")
    }

    private func createFolderIfNeededForScript(withIdentifier identifier: String, file: File) throws -> Folder {
        let scriptFolder = try folder.createSubfolderIfNeeded(withName: identifier)
        try packageManager.symlinkPackages(to: scriptFolder)

        if (try? scriptFolder.file(named: "OriginalFile")) == nil {
            try scriptFolder.createSymlink(to: file.path, at: "OriginalFile")
        }

        let sourcesFolder = try scriptFolder.createSubfolderIfNeeded(withName: "Sources")
        try sourcesFolder.createFile(named: "main.swift", contents: file.read())

        return scriptFolder
    }

    private func folderForScript(withIdentifier identifier: String) -> Folder? {
        return try? folder.subfolder(named: identifier)
    }

    private func addDependencyScripts(fromMarathonFile file: MarathonFile, toFolder folder: Folder) throws {
        for url in file.scriptURLs {
            do {
                let script = try File(path: url.absoluteString)
                let sourcesFolder = try folder.subfolder(named: "Sources")
                let copy = try sourcesFolder.createFile(named: script.name)
                try copy.write(data: script.read())
            } catch {
                throw Error.failedToAddDependencyScript(url.absoluteString)
            }
        }
    }

    private func makeManagedScriptPathList() -> [String] {
        return folder.subfolders.flatMap { scriptFolder in
            guard let path = try? scriptFolder.moveToAndPerform(command: "readlink OriginalFile") else {
                return nil
            }

            // Take the opportunity to clean up cache data no longer needed
            guard !path.isEmpty else {
                try? scriptFolder.delete()
                return nil
            }

            return path
        }
    }
}
