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

        let destination = try destinationFolder()
        try overwriteIfNeeded(destination: destination, scriptName: script.name)

        let tempFile = try script.folder.createFile(named: script.name.asScriptPath())
        try tempFile.write(data: try script.folder.file(named: "OriginalFile").read())

        try perform(export(tempFile, to: destination), orThrow: Error.failedToExportScript(tempFile.name))
        try tempFile.delete()
    }

    private func destinationFolder() throws -> Folder {
        let folder: Folder
        if arguments.count > 1 && !arguments[1].contains("--force") {
            folder = try FileSystem().createFolderIfNeeded(at: arguments[1])
        } else {
            folder = FileSystem().currentFolder
        }
        return folder
    }

    private func overwriteIfNeeded(destination: Folder, scriptName: String) throws {
        let exportPath = destination.path.appending(scriptName)
        let existingProjectFolder = try? destination.subfolder(atPath: scriptName)

        if existingProjectFolder != nil && !arguments.contains("--force") {
            printer.output("⚠️  A directory already exists at \(exportPath)")
            printer.output("❓  Are you sure you want to overwrite it? (Type 'Y' to confirm)")
            if readLine()?.lowercased() == "n" {
                exit(1)
            }
        }
        try existingProjectFolder?.delete()
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

private extension String {
    var asScriptName: String {
        return replacingOccurrences(of: ".swift", with: "")
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
