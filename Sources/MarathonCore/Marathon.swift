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

    public static func run(with arguments: [String] = CommandLine.arguments,
                           folderPath: String = "~/.marathon",
                           printer: @escaping Printer = { print($0) }) throws {
        let command = try Command(arguments: arguments)
        let fileSystem = FileSystem()

        let setupError = Error.couldNotPerformSetup(folderPath)
        let rootFolder = try perform(fileSystem.createFolderIfNeeded(at: folderPath), orThrow: setupError)
        let packageFolder = try perform(rootFolder.createSubfolderIfNeeded(withName: "Packages"), orThrow: setupError)
        let scriptFolder = try perform(rootFolder.createSubfolderIfNeeded(withName: "Scripts"), orThrow: setupError)

        let verbosePrinter = makeVerbosePrinter(from: printer, for: command)
        let packageManager = try perform(PackageManager(folder: packageFolder, printer: verbosePrinter), orThrow: setupError)
        let scriptManager = ScriptManager(folder: scriptFolder, packageManager: packageManager, printer: verbosePrinter)

        let task = command.makeTaskClosure(fileSystem.currentFolder,
                                           Array(arguments.dropFirst(2)),
                                           scriptManager, packageManager,
                                           printer)

        try task.execute()
    }

    // MARK: - Private

    private static func makeVerbosePrinter(from printer: @escaping Printer, for command: Command) -> Printer {
        guard command.allowsVerboseOutput else {
            return { _ in }
        }

        var isFirstOutput = true

        return { message in
            printer(message.withIndentedNewLines(prefix: isFirstOutput ? "🏃  " : "   "))
            isFirstOutput = false
        }
    }
}
