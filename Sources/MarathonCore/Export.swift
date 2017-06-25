/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

// MARK: - Error

public enum ExportError {
    case missingPath
    case failedToExportScript(String)
}

extension ExportError: PrintableError {
    public var message: String {
        switch self {
        case .missingPath:
            return "No script name/path given"
        case .failedToExportScript(let name):
            return "Failed to export script \(name)"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingPath:
            return ["Pass the name/path of a script file to export (for example 'marathon export myScript')"]
        case .failedToExportScript:
            return ["Remove directory or provide alternate export path"]
        }
    }
}

// MARK: - Task

internal final class ExportTask: Task, Executable {
    private typealias Error = ExportError

    func execute() throws {

        guard let exportScriptPath = arguments.first?.asScriptPath() else {
            throw Error.missingPath
        }

        let script = try scriptManager.script(atPath: exportScriptPath, allowRemote: false)

        let destination = try makeDestinationFolder()
        try overwriteDestinationIfNeeded(destination: destination, scriptName: script.name)

        let tempFile = try script.folder.createFile(named: script.name.asScriptPath())
        try tempFile.write(data: try script.folder.file(named: "OriginalFile").read())

        try perform(export(tempFile, to: destination), orThrow: Error.failedToExportScript(tempFile.name))
        try tempFile.delete()
    }

    private func makeDestinationFolder() throws -> Folder {
        if let path = arguments.element(at: 1), path != "--force" {
            return try FileSystem().createFolderIfNeeded(at: path)
        } else {
            return FileSystem().currentFolder
        }
    }

    private func overwriteDestinationIfNeeded(destination: Folder, scriptName: String) throws {
        let exportPath = destination.path.appending(scriptName)
        let existingProjectFolder = try? destination.subfolder(atPath: scriptName)

        if existingProjectFolder != nil && !arguments.contains("--force") {
            printer.output("⚠️  A directory already exists at \(exportPath)")
            printer.output("❓  Are you sure you want to overwrite it? (Type 'Y' to confirm)")
            if readLine()?.lowercased() != "y" {
                exit(1)
            }
        }
        try existingProjectFolder?.delete()
    }

    private func export(_ file: File, to folder: Folder) throws {
        let projectFolder = try folder.createSubfolder(named: file.scriptName)

        let packageFile = try projectFolder.createFile(named: "Package.swift")
        let packages = try resolvePackages(from: file)
        let packageManifestString = try packageManager.makePackageManifestString(forScriptWithName: file.scriptName, packages: packages)
        try packageFile.write(string: packageManifestString)

        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
        let scriptFileString = try makeFileStringWithInlineDependencies(for: file, using: packages)
        let scriptFile = try sourcesFolder.createFile(named: file.name)
        try scriptFile.write(string: scriptFileString)
    }

    private func resolvePackages(from file: File) throws -> [Package] {
        let importNames = try Set(file.importNames())
        let scriptPackages = packageManager.addedPackages.filter { importNames.contains($0.name) }
        return scriptPackages
    }

    private func makeFileStringWithInlineDependencies(for file: File, using packages: [Package]) throws -> String {
        let importLines = try file.importLines()
        let tuples: [(current: String, replacement: String)] = importLines.reduce([]) { partialResult, importLine in
            guard let package = packages.first(where: { package in importLine.contains(package.name) }) else {
                return partialResult
            }
            let tuple: (String, String) = (importLine, "import \(package.name) // marathon:\(package.url)")
            return partialResult + [tuple]
        }

        let fileString = tuples.reduce(try file.readAsString()) { partialResult, tuple in
            return partialResult.replacingOccurrences(of: tuple.current, with: tuple.replacement)
        }

        return fileString
    }
}

private extension File {
    var scriptName: String {
        return name.replacingOccurrences(of: ".swift", with: "")
    }

    func importLines() throws -> [String] {
        return try readAsString()
            .components(separatedBy: .newlines)
            .filter { $0.hasPrefix("import") }
    }

    func importNames() throws -> [String] {
        return try importLines()
            .flatMap { $0.components(separatedBy: .whitespaces) }
            .filter { !$0.hasPrefix("import") && !$0.hasPrefix("//") && !$0.hasPrefix("marathon") }
    }
}
