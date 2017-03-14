/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

public final class Marathon {
    public enum Error: Swift.Error {
        case couldNotPerformSetup(String)
    }

    private struct Folders {
        let module: Folder
        let scripts: Folder
        let packages: Folder
    }

    // MARK: - API

    public static func run(with arguments: [String] = CommandLine.arguments, folderPath: String = "~/.marathon") throws -> String {
        let command = try Command(arguments: arguments)

        let setupError = Error.couldNotPerformSetup(folderPath)
        let rootFolder = try perform(FileSystem().createFolderIfNeeded(at: folderPath), orThrow: setupError)
        let packageFolder = try perform(rootFolder.createSubfolderIfNeeded(withName: "Packages"), orThrow: setupError)
        let scriptFolder = try perform(rootFolder.createSubfolderIfNeeded(withName: "Scripts"), orThrow: setupError)

        let packageManager = try perform(PackageManager(folder: packageFolder), orThrow: setupError)
        let scriptManager = ScriptManager(folder: scriptFolder, packageManager: packageManager)

        let executionFolder = try Folder(path: "")
        let task = command.makeTaskClosure(executionFolder, Array(arguments.dropFirst(2)), scriptManager, packageManager)
        return try task.execute()
    }
}
