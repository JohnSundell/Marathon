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
    case failedToRemoveScriptFolder(Folder)
}

extension ScriptManagerError: PrintableError {
    public var message: String {
        switch self {
        case .scriptNotFound(let path):
            return "Could not find a Swift script at '\(path)'"
        case .failedToCreatePackageFile(_):
            return "Failed to create a Package.swift file for the script"
        case .failedToRemoveScriptFolder(_):
            return "Failed to remove script folder"
        }
    }

    public var hint: String? {
        switch self {
        case .scriptNotFound(_):
            return "Please check that the path is valid and try again"
        case .failedToCreatePackageFile(let folder),
             .failedToRemoveScriptFolder(let folder):
            return "Make sure you have write permissions to the folder '\(folder.path)'"
        }
    }
}

// MARK: - ScriptManager

internal final class ScriptManager {
    private typealias Error = ScriptManagerError

    var managedScriptPaths: [String] { return makeManagedScriptPathList() }

    private let folder: Folder
    private let packageManager: PackageManager

    // MARK: - Init

    init(folder: Folder, packageManager: PackageManager) {
        self.folder = folder
        self.packageManager = packageManager
    }

    // MARK: - API

    func script(at path: String) throws -> Script {
        let file = try perform(File(path: path), orThrow: Error.scriptNotFound(path))
        let identifier = scriptIdentifier(from: file)
        let name = identifier.components(separatedBy: "-").last!.capitalized
        let folder = try createFolderIfNeededForScript(withIdentifier: identifier, file: file)
        let script = Script(name: name, folder: folder)

        if let marathonFile = script.marathonFile {
            try packageManager.addPackages(fromMarathonFile: marathonFile)
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
        let file = try perform(File(path: path), orThrow: Error.scriptNotFound(path))
        let identifier = scriptIdentifier(from: file)

        guard let folder = folderForScript(withIdentifier: identifier) else {
            return
        }

        try perform(folder.delete(), orThrow: Error.failedToRemoveScriptFolder(folder))
    }

    // MARK: - Private

    private func scriptIdentifier(from file: File) -> String {
        let pathExcludingExtension = file.parent!.path + file.nameExcludingExtension
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

    private func makeManagedScriptPathList() -> [String] {
        return folder.subfolders.flatMap { scriptFolder in
            return try? scriptFolder.moveToAndPerform(command: "OriginalFile")
        }
    }
}
