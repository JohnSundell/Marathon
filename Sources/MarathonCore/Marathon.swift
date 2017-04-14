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
                           printer: Printer? = nil) throws {
        let task = try resolveTask(for: arguments, folderPath: folderPath, printer: printer)
        try task.execute()
    }

    // MARK: - Private

    private static func resolveTask(for arguments: [String], folderPath: String, printer: Printer?) throws -> Executable {
        let command = try Command(arguments: arguments)
        let printer = printer ?? makeDefaultPrinter(for: command, arguments: arguments)
        let fileSystem = FileSystem()

        do {
            let rootFolder = try fileSystem.createFolderIfNeeded(at: folderPath)
            let packageFolder = try rootFolder.createSubfolderIfNeeded(withName: "Packages")
            let scriptFolder = try rootFolder.createSubfolderIfNeeded(withName: "Scripts")

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

    private static func makeDefaultPrinter(for command: Command, arguments: [String]) -> Printer {
        let progressFunction = makeProgressPrintingFunction(for: command)
        let verboseFunction = makeVerbosePrintingFunction(for: arguments, progressFunction: progressFunction)

        return Printer(
            outputFunction: { print($0) },
            progressFunction: progressFunction,
            verboseFunction: verboseFunction
        )
    }

    private static func makeProgressPrintingFunction(for command: Command) -> VerbosePrintFunction {
        var isFirstOutput = true

        return { (messageExpression: () -> String) in
            guard command.allowsProgressOutput else {
                return
            }

            let message = messageExpression()
            print(message.withIndentedNewLines(prefix: isFirstOutput ? "🏃  " : "   "))

            isFirstOutput = false
        }
    }

    private static func makeVerbosePrintingFunction(for arguments: [String],
                                                    progressFunction: @escaping VerbosePrintFunction) -> VerbosePrintFunction {
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
}
