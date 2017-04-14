/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import Require

// MARK: - Error

public enum ScriptManagerError {
    case scriptNotFound(String)
    case failedToCreatePackageFile(Folder)
    case failedToAddDependencyScript(String)
    case failedToRemoveScriptFolder(Folder)
    case failedToDownloadScript(URL)
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
        case .failedToDownloadScript(let url):
            return "Failed to download script from '\(url.absoluteString)'"
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
        case .failedToDownloadScript(_):
            return ["Make sure that the URL is reachable, and that it contains a valid Swift script"]
        }
    }
}

// MARK: - ScriptManager

internal final class ScriptManager {
    private typealias Error = ScriptManagerError

    var managedScriptPaths: [String] { return makeManagedScriptPathList() }

    private let cacheFolder: Folder
    private let temporaryFolder: Folder
    private lazy var temporaryScriptFiles = [File]()
    private let packageManager: PackageManager
    private let printer: Printer

    // MARK: - Lifecycle

    init(folder: Folder, packageManager: PackageManager, printer: Printer) throws {
        self.cacheFolder = try folder.createSubfolderIfNeeded(withName: "Cache")
        self.temporaryFolder = try folder.createSubfolderIfNeeded(withName: "Temp")
        self.packageManager = packageManager
        self.printer = printer
    }

    deinit {
        for file in temporaryScriptFiles {
            try? removeDataForScript(at: file.path)
            try? file.parent?.delete()
        }
    }

    // MARK: - API

    func script(at path: String) throws -> Script {
        let file = try perform(File(path: path), orThrow: Error.scriptNotFound(path))
        return try script(from: file)
    }

    func downloadScript(from url: URL) throws -> Script {
        do {
            let url = url.transformIfNeeded()

            printer.reportProgress("Downloading script...")
            let data = try Data(contentsOf: url)

            printer.reportProgress("Saving script...")
            let identifier = scriptIdentifier(from: url.absoluteString)
            let folder = try temporaryFolder.createSubfolderIfNeeded(withName: identifier)
            let fileName = scriptName(from: identifier) + ".swift"
            let file = try folder.createFile(named: fileName, contents: data)
            temporaryScriptFiles.append(file)

            printer.reportProgress("Resolving Marathonfile...")
            if let parentURL = url.parent {
                let marathonFileURL = URL(string: parentURL.absoluteString + "Marathonfile").require()

                if let marathonFileData = try? Data(contentsOf: marathonFileURL) {
                    printer.reportProgress("Saving Marathonfile...")
                    try folder.createFile(named: "Marathonfile", contents: marathonFileData)
                }
            }

            return try script(from: file)
        } catch {
            throw Error.failedToDownloadScript(url)
        }
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

    private func script(from file: File) throws -> Script {
        let identifier = scriptIdentifier(from: file.path)
        let name = scriptName(from: identifier)
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

    private func scriptIdentifier(from path: String) -> String {
        let pathExcludingExtension = path.components(separatedBy: ".swift").first.require()
        return pathExcludingExtension.replacingOccurrences(of: "/", with: "-")
                                     .replacingOccurrences(of: " ", with: "-")
    }

    private func scriptName(from identifier: String) -> String {
        return identifier.components(separatedBy: "-").last.require().capitalized
    }

    private func createFolderIfNeededForScript(withIdentifier identifier: String, file: File) throws -> Folder {
        let scriptFolder = try cacheFolder.createSubfolderIfNeeded(withName: identifier)
        try packageManager.symlinkPackages(to: scriptFolder)

        if (try? scriptFolder.file(named: "OriginalFile")) == nil {
            try scriptFolder.createSymlink(to: file.path, at: "OriginalFile", printer: printer)
        }

        let sourcesFolder = try scriptFolder.createSubfolderIfNeeded(withName: "Sources")
        try sourcesFolder.empty()
        try sourcesFolder.createFile(named: "main.swift", contents: file.read())

        return scriptFolder
    }

    private func folderForScript(withIdentifier identifier: String) -> Folder? {
        return try? cacheFolder.subfolder(named: identifier)
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
        return cacheFolder.subfolders.flatMap { scriptFolder in
            guard let path = try? scriptFolder.moveToAndPerform(command: "readlink OriginalFile", printer: printer) else {
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
