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
    case failedToCreateTestsFile(Folder)
    case failedToAddDependencyScript(String)
    case failedToRemoveScriptFolder(Folder)
    case failedToDownloadScript(URL, Error)
    case invalidInlineDependencyURL(String)
    case noSwiftFilesInRepository(URL)
    case multipleSwiftFilesInRepository(URL, [File])
}

extension ScriptManagerError: PrintableError {
    public var message: String {
        switch self {
        case .scriptNotFound(let path):
            return "Could not find a Swift script at '\(path)'"
        case .failedToCreatePackageFile(_):
            return "Failed to create a Package.swift file for the script"
        case .failedToCreateTestsFile(_):
            return "Failed to create tests file for the script"
        case .failedToAddDependencyScript(let path):
            return "Failed to add the dependency script at '\(path)'"
        case .failedToRemoveScriptFolder(_):
            return "Failed to remove script folder"
        case .failedToDownloadScript(let url, let error):
            return "Failed to download script from '\(url.absoluteString)' (\(error))"
        case .invalidInlineDependencyURL(let urlString):
            return "Could not resolve inline dependency '\(urlString)'"
        case .noSwiftFilesInRepository(let url):
            return "No Swift files found in repository at '\(url.absoluteString)'"
        case .multipleSwiftFilesInRepository(let url, _):
            return "Multiple Swift files found in repository at '\(url.absoluteString)'"
        }
    }

    public var hints: [String] {
        switch self {
        case .scriptNotFound(_):
            return ["Please check that the path is valid and try again"]
        case .failedToCreatePackageFile(let folder),
             .failedToRemoveScriptFolder(let folder),
             .failedToCreateTestsFile(let folder):
            return ["Make sure you have write permissions to the folder '\(folder.path)'"]
        case .failedToAddDependencyScript(_):
            return ["Make sure that the file exists and is readable"]
        case .failedToDownloadScript(_):
            return ["Make sure that the URL is reachable, and that it contains a valid Swift script"]
        case .invalidInlineDependencyURL, .noSwiftFilesInRepository:
            return ["Please verify that the URL is correct and try again"]
        case .multipleSwiftFilesInRepository(_, let files):
            let fileNames = files.map({ $0.name }).joined(separator: "\n- ")
            return ["Please run one of the following scripts using its direct URL instead:\n- \(fileNames)"]
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
        if let file = try? File(path: path.asScriptPath()) {
            return try script(from: file)
        }

        if !path.hasPrefix("http") && !path.hasPrefix("git@") && !path.hasPrefix("github") {
            guard let gitHubURL = URL(string: "https://github.com/\(path).git") else {
                throw Error.scriptNotFound(path)
            }

            return try downloadScriptFromRepository(at: gitHubURL)
        }

        guard let url = URL(string: path) else {
            throw Error.scriptNotFound(path)
        }

        if path.hasSuffix(".git") {
            return try downloadScriptFromRepository(at: url)
        }

        return try downloadScript(from: url)
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
    
    func addTest(file testFile: File, to script: Script) throws {
        do {
            try createTestsFolderIfNeeded(for: script, file: testFile)
        } catch {
            throw Error.failedToCreateTestsFile(script.folder)
        }
    }

    // MARK: - Private

    private func script(from file: File) throws -> Script {
        let identifier = scriptIdentifier(from: file.path)
        let name = scriptName(from: identifier)
        let folder = try createFolderIfNeededForScript(withIdentifier: identifier, file: file)
        let script = Script(name: name, folder: folder, printer: printer)

        if let marathonFile = try script.resolveMarathonFile() {
            try packageManager.addPackagesIfNeeded(from: marathonFile.packageURLs)
            try addDependencyScripts(fromMarathonFile: marathonFile, toFolder: folder)
        }

        try resolveInlineDependencies(from: file)

        do {
            let packageFile = try folder.createFile(named: "Package.swift")
            try packageFile.write(string: packageManager.makePackageDescription(for: script))
        } catch {
            throw Error.failedToCreatePackageFile(folder)
        }

        return script
    }

    private func downloadScript(from url: URL) throws -> Script {
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
            throw Error.failedToDownloadScript(url, error)
        }
    }

    private func downloadScriptFromRepository(at url: URL) throws -> Script {
        let identifier = scriptIdentifier(from: url.absoluteString)
        let folder = try temporaryFolder.createSubfolderIfNeeded(withName: identifier)
        try folder.empty()

        do {
            printer.reportProgress("Cloning \(url)...")
            let cloneCommand = "git clone \(url.absoluteString) clone -q"
            try folder.moveToAndPerform(command: cloneCommand, printer: printer)
        } catch {
            throw Error.failedToDownloadScript(url, error)
        }

        let cloneFolder = try folder.subfolder(named: "clone")

        let swiftFiles = cloneFolder.makeFileSequence(recursive: true).filter { file in
            return file.extension == "swift" && file.nameExcludingExtension != "Package"
        }

        switch swiftFiles.count {
        case 0:
            throw Error.noSwiftFilesInRepository(url)
        case 1:
            return try script(from: swiftFiles[0])
        default:
            throw Error.multipleSwiftFilesInRepository(url, swiftFiles)
        }
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
    
    @discardableResult private func createTestsFolderIfNeeded(for script: Script, file: File) throws -> Folder {
        if (try? script.folder.file(named: "OriginalTestsFile")) == nil {
            try script.folder.createSymlink(to: file.path, at: "OriginalTestsFile", printer: printer)
        }
        
        let testsFolder = try script.folder.createSubfolderIfNeeded(withName: "Tests")
        try testsFolder.empty()
        
        let testsModuleFolder = try testsFolder.createSubfolder(named: script.name + "Tests")
        try testsModuleFolder.empty()
        try testsModuleFolder.createFile(named: file.name, contents: file.read())
        
        // TODO: Determine why LinuxMain.swift is missing from the .xcodeproj when opened.
        // It might be because I'm not on Linux? See if someone can verify that assumption.
        let content = "import XCTest\n" +
                "@testable import \(script.name)\n\n" +
                "XCTMain([\n" +
                "\ttestCase(\(script.name).allTests),\n" +
                "])\n"
        let data = content.data(using: .utf8)!
        
        try testsFolder.createFile(named: "LinuxMain.swift", contents: data)
        
        return testsFolder
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

    private func resolveInlineDependencies(from file: File) throws {
        let lines = try file.readAsString().components(separatedBy: .newlines)
        var packageURLs = [URL]()

        for line in lines {
            if line.hasPrefix("import ") {
                let components = line.components(separatedBy: "marathon:")

                guard components.count > 1 else {
                    continue
                }

                let urlString = components.last!.trimmingCharacters(in: .whitespaces)

                guard let url = URL(string: urlString) else {
                    throw Error.invalidInlineDependencyURL(urlString)
                }

                packageURLs.append(url)
            } else if let firstCharacter = line.unicodeScalars.first {
                guard !CharacterSet.alphanumerics.contains(firstCharacter) else {
                    break
                }
            }
        }

        try packageManager.addPackagesIfNeeded(from: packageURLs)
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
