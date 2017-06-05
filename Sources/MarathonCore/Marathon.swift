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
                           printFunction: @escaping PrintFunction = { print($0) }) throws {
        let task = try resolveTask(for: arguments, folderPath: folderPath, printFunction: printFunction)
        try task.execute()
    }

    // MARK: - Private

    private static func resolveTask(for arguments: [String],
                                    folderPath: String,
                                    printFunction: @escaping PrintFunction) throws -> Executable {
        let command = try Command(arguments: arguments)
        let printer = makePrinter(using: printFunction, command: command, arguments: arguments)
        let fileSystem = FileSystem()

        do {
            let rootFolder = try fileSystem.createFolderIfNeeded(at: folderPath)
            let packageFolder = try rootFolder.createSubfolderIfNeeded(withName: "Packages")
            let scriptFolder = try rootFolder.createSubfolderIfNeeded(withName: "Scripts")
            let autocompletionsFolder = try rootFolder.createSubfolderIfNeeded(withName: "ShellAutocomplete")

            installShellAutocompleteIfNeeded(in: autocompletionsFolder)

            let packageManager = try PackageManager(folder: packageFolder, printer: printer)
            let scriptManager = try ScriptManager(folder: scriptFolder, packageManager: packageManager, printer: printer)

            return command.makeTaskClosure(fileSystem.currentFolder,
                                           Array(arguments.dropFirst(2)),
                                           scriptManager, packageManager,
                                           printer)
        } catch {
            throw Error.couldNotPerformSetup(folderPath)
        }
    }

    private static func makePrinter(using printFunction: @escaping PrintFunction,
                                    command: Command,
                                    arguments: [String]) -> Printer {
        let progressFunction = makeProgressPrintingFunction(using: printFunction, command: command, arguments: arguments)
        let verboseFunction = makeVerbosePrintingFunction(using: progressFunction, arguments: arguments)

        return Printer(
            outputFunction: printFunction,
            progressFunction: progressFunction,
            verboseFunction: verboseFunction
        )
    }

    private static func makeProgressPrintingFunction(using printFunction: @escaping PrintFunction,
                                                     command: Command,
                                                     arguments: [String]) -> VerbosePrintFunction {
        var isFirstOutput = true
        let shouldPrint = command.allowsProgressOutput || arguments.contains("--verbose")

        return { (messageExpression: () -> String) in
            guard shouldPrint else {
                return
            }

            let message = messageExpression()
            printFunction(message.withIndentedNewLines(prefix: isFirstOutput ? "🏃  " : "   "))

            isFirstOutput = false
        }
    }

    private static func makeVerbosePrintingFunction(using progressFunction: @escaping VerbosePrintFunction,
                                                    arguments: [String]) -> VerbosePrintFunction {
        let allowVerboseOutput = arguments.contains("--verbose")

        return { (messageExpression: () -> String) in
            guard allowVerboseOutput else {
                return
            }

            // Make text italic
            let message = "\u{001B}[0;3m\(messageExpression())\u{001B}[0;23m"
            progressFunction(message)
        }
    }

    private static func installShellAutocompleteIfNeeded(in folder: Folder) {
        ZshAutocompleteInstaller.installIfNeeded(in: folder)
        FishAutocompleteInstaller.installIfNeeded(in: folder)
    }
}
