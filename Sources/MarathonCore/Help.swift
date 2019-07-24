/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Task

internal final class HelpTask: Task, Executable {
    // MARK: - Executable

    func execute() throws {
        let command = try Command(arguments: arguments, index: 0)
        let title = makeTitle(for: command)
        let message = makeMessage(for: command)
        var output = title + "\n" + title.dashesWithMatchingLength

        if command == .help {
            output.append("-\n")
            output.append(message)
        } else {
            output.append("\n" + command.description + "\n\n")
            output.append("👉  Usage: 'marathon \(command.rawValue)")

            if !command.usageText.isEmpty {
                output.append(" \(command.usageText)")
            }

            output.append("'")

            if !message.isEmpty {
                output.append("\n\n" + message.withIndentedNewLines(prefix: "ℹ️  "))
            }
        }

        printer.output(output)
    }

    // MARK: - Private

    private func makeTitle(for command: Command) -> String {
        guard command != .help else {
            return "Welcome to Marathon 🏃"
        }

        return command.makeTitle()
    }

    private func makeMessage(for command: Command) -> String {
        switch command {
        case .create, .edit:
            return "The script will be opened for editing in Xcode by default\n" +
                   "To open the source file directly (without an Xcode project), pass the '--no-xcode' flag\n" +
                   "To not open the script at all, pass the '--no-open' flag"
        case .remove:
            return "You can use this command to clean up data for scripts or packages no longer needed. To list them, use 'marathon list'\n" +
                   "To remove all script data, pass the '--all-script-data' flag" +
                   "To remove all packages, pass the '--all-packages' flag"
        case .run:
            return "The script will be compiled and run, and any output generated will be returned"
        case .install:
            return "The script will be compiled, and the resulting binary copied to the install path\n" +
                   "The default install path is '/usr/local/bin/<lowercased-name-of-script>'\n" +
                   "Marathon will ask before overwriting any existing binary, unless the '--force' flag is passed"
        case .add:
            return "You can also use a 'Marathonfile' to automatically add packages. See https://github.com/johnsundell/marathon for more information"
        case .list:
            return "You can remove any packages or script data no longer needed using 'marathon remove'"
        case .update:
            return ""
        case .help:
            return makeWelcomeMessage()
        }
    }

    private func makeWelcomeMessage() -> String {
        var message = "Marathon makes it easy to write, run and manage your Swift scripts.\n\n"
        message.append("These are the available commands:\n\n")

        for command in Command.all {
            message.append(command.makeTitle(withPadding: true) + command.description + "\n")
        }

        message.append("\n👉  You can also type a command you wish to know more about after 'help'\n")
        message.append("   For example: 'marathon help create' will show information about the 'create' command\n\n")
        message.append("🌏  For more information, go to https://github.com/johnsundell/marathon")

        return message
    }
}

// MARK: - Utilities

private extension Command {
    func makeTitle(withPadding addPadding: Bool = false) -> String {
        let title = emoji + (addPadding ? "    " : "  ") + rawValue

        guard addPadding else {
            return title
        }

        let paddingNeeded = 10 - rawValue.count

        guard paddingNeeded > 0 else {
            return title
        }

        return title + String(repeating: " ", count: paddingNeeded)
    }

    private var emoji: String {
        switch self {
        case .create:
            return "🐣"
        case .edit:
            return "✏️"
        case .remove:
            return "🗑"
        case .run:
            return "🏃‍♀️"
        case .install:
            return "💻"
        case .add:
            return "📦"
        case .list:
            return "📋"
        case .update:
            return "♻️"
        case .help:
            return "ℹ️"
        }
    }
}
