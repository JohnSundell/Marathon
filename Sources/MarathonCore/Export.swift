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
    case noMarathonScriptFound
    case failedToExportScript(String)
}

extension ExportError: PrintableError {
    public var message: String {
        switch self {
        case .missingPath:
            return "No script name/path given"
        case .noMarathonScriptFound:
            return "No marathon scripts found"
        case .failedToExportScript(let name):
            return "Failed to export script \(name)"
        }
    }

    public var hints: [String] {
        switch self {
        case .missingPath:
            return ["Pass the name/path of a script file to export (for example 'marathon export myScript')"]
        case .noMarathonScriptFound:
            return ["Marathon can only export scripts managed by marathon"]
        case .failedToExportScript:
            return ["Remove directory or provide alternate export path"]
        }
    }
}

// MARK: - Task

internal final class ExportTask: Task, Executable {
    private typealias Error = ExportError

    func execute() throws {

        // Required argument given?
        guard let scriptNameOrPath = arguments.first?.asScriptPath() else {
            throw Error.missingPath
        }

        // Script Name or Full Script Path given?
        let isScriptName = scriptNameOrPath.components(separatedBy: "/").count == 1

        let file: File
        if isScriptName {
            // Does File exist in current directory?
            file = try FileSystem().currentFolder.file(atPath: scriptNameOrPath)
        } else {
            // Does File exist at full path?
            file = try FileSystem().createFile(at: scriptNameOrPath)
        }

        // Is the File a script managed by marathon?
        let isManagedScript = !(scriptManager.managedScriptPaths.filter { $0 == file.path }.isEmpty)
        guard isManagedScript else {
            throw Error.noMarathonScriptFound
        }

        let exportFolder: Folder
        if arguments.count > 1 && !arguments[1].contains("--force") {
            // If more than one argument, try to create Folder at export-path
            exportFolder = try FileSystem().createFolderIfNeeded(at: arguments[1])
        } else {
            // Otherwise use default export path
            exportFolder = FileSystem().currentFolder
        }

        let scriptName = file.scriptName
        let exportPath = exportFolder.path.appending(scriptName)

        // If directory already exists at path and --force flag not passed, then ask for overwrite permission
        let existingProjectFolder = try? exportFolder.subfolder(atPath: scriptName)
        if existingProjectFolder != nil && !arguments.contains("--force") {
            printer.output("⚠️  A directory already exists at \(exportPath)")
            printer.output("❓  Are you sure you want to overwrite it? (Type 'Y' to confirm)")
            if readLine()?.lowercased() == "n" {
                exit(1)
            }
        }

        try existingProjectFolder?.delete() // Otherwise, delete the existing folder if it exists
        try perform(export(file, to: exportFolder), orThrow: Error.failedToExportScript(file.name))
    }

    private func export(_ file: File, to folder: Folder) throws {
        let projectFolder = try folder.createSubfolder(named: file.scriptName)

        let packageFile = try projectFolder.createFile(named: "Package.swift")
        let packages = try resolvePackages(from: file)
        let packageFileString = try makePackageFileString(for: file, with: packages)
        try packageFile.write(string: packageFileString)

        let sourcesFolder = try projectFolder.createSubfolder(named: "Sources")
        let scriptFileString = try makeFileStringWithInlineDependencies(for: file, using: packages)
        let scriptFile = try sourcesFolder.createFile(named: file.name)
        try scriptFile.write(string: scriptFileString)
    }

    private func resolvePackages(from file: File) throws -> [Package] {
        let importNames = try file.importNames()
        let allManagedPackages = packageManager.addedPackages
        let scriptPackages: [Package] = importNames.flatMap { name in
            if let scriptPackage = allManagedPackages.first(where: { $0.name.lowercased() == name.lowercased() }) {
                return scriptPackage
            } else {
                return nil
            }
        }
        return scriptPackages
    }

    private func makePackageFileString(for file: File, with packages: [Package]) throws -> String {
        let base = "import PackageDescription\n"
            + "\n"
            + "let package = Package(\n"
            + "    name: \"\(file.scriptName)\",\n"
            + "    dependencies: [\n"

        let baseWithPackages = packages.reduce(base) { partialResult, package in
            let string = "        .Package(url: \"\(package.url)\", majorVersion: \(package.majorVersion)),\n"
            return partialResult.appending(string)
        }
        return baseWithPackages.appending("    ]\n)\n")
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
