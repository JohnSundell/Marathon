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
        let task = try resolveTask(forArguments: arguments, folderPath: folderPath, printer: printer)
        try task.execute()
    }

    // MARK: - Private

    private static func resolveTask(forArguments arguments: [String], folderPath: String, printer: @escaping Printer) throws -> Executable {
        let command = try Command(arguments: arguments)
        let fileSystem = FileSystem()

        do {
            let rootFolder = try fileSystem.createFolderIfNeeded(at: folderPath)
            let packageFolder = try rootFolder.createSubfolderIfNeeded(withName: "Packages")
            let scriptFolder = try rootFolder.createSubfolderIfNeeded(withName: "Scripts")

            let progressPrinter = makeProgressPrinter(from: printer, for: command)
            let packageManager = try PackageManager(folder: packageFolder, printer: progressPrinter)
            let scriptManager = try ScriptManager(folder: scriptFolder, packageManager: packageManager, printer: progressPrinter)

            return command.makeTaskClosure(fileSystem.currentFolder,
                                           Array(arguments.dropFirst(2)),
                                           scriptManager, packageManager,
                                           progressPrinter,
                                           printer)
        } catch {
            throw Error.couldNotPerformSetup(folderPath)
        }
    }

    private static func makeProgressPrinter(from printer: @escaping Printer, for command: Command) -> Printer {
        guard command.allowsProgressOutput else {
            return { _ in }
        }

        var isFirstOutput = true

        return { message in
            printer(message.withIndentedNewLines(prefix: isFirstOutput ? "🏃  " : "   "))
            isFirstOutput = false
        }
    }
}
