/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

// MARK: - Error

public enum CommandError: PrintableError {
    case invalid(String)
}

public extension CommandError {
    var message: String {
        switch self {
        case .invalid(let command):
            return "'\(command)' is not a valid command"
        }
    }

    var hints: [String] {
        return ["Type 'marathon help' for available commands"]
    }
}

// MARK: - Command

enum Command: RawRepresentable, CustomStringConvertible {
    
    private typealias Error = CommandError
    
    case create(arguments: [String])
    case edit(arguments: [String])
    case remove(arguments: [String])
    case run(arguments: [String])
    case install(arguments: [String])
    case add(arguments: [String])
    case list
    case update
    case help
    
    init?(rawValue: String) {
        try? self.init(command: rawValue)
    }
    
    init(command: String, arguments: [String] = []) throws {
        if command == "create" {
            self = .create(arguments: arguments)
        } else if command == "edit" {
            self = .edit(arguments: arguments)
        } else if command == "remove" {
            self = .remove(arguments: arguments)
        } else if command == "run" {
            self = .run(arguments: arguments)
        } else if command == "install" {
            self = .install(arguments: arguments)
        } else if command == "add" {
            self = .add(arguments: arguments)
        } else if command == "list" {
            self = .list
        } else if command == "update" {
            self = .update
        } else if command == "help" {
            self = .help
        } else {
            throw Error.invalid(command)
        }
    }
    
    static let all: [Command] = [.create(arguments: []), .edit(arguments: []), .remove(arguments: []), .run(arguments: []), .install(arguments: []), .add(arguments: []), .list, .update, .help]
    
    var description: String {
        switch self {
        case .create:
            return "Create new script at a given path and open it"
        case .edit:
            return "Edit a script at a given path"
        case .remove:
            return "Remove a package or the cache data for a script at a given path"
        case .run:
            return "Run a script at a given path"
        case .install:
            return "Install a script at a given path or URL as a binary"
        case .add:
            return "Add a package from a given URL to be able to use it from your scripts"
        case .list:
            return "List all packages and cached script data"
        case .update:
            return "Update all added packages to their latest versions"
        case .help:
            return "Print these instructions"
        }
    }
    
    var rawValue: String {
        switch self {
        case .create:
            return "create"
        case .edit:
            return "edit"
        case .remove:
            return "remove"
        case .run:
            return "run"
        case .install:
            return "install"
        case .add:
            return "add"
        case .list:
            return "list"
        case .update:
            return "update"
        case .help:
            return "help"
        }
    }
    
    func makeExecutable(_ folderPath: String, _ printer: Printer, _ options: [Option]) -> Executable? {
        switch self {
        case .create(let arguments):
            return CreateTask(arguments: arguments, rootFolderPath: folderPath, printer: printer, options: options)
        case .edit(let arguments):
            return EditTask(arguments: arguments, rootFolderPath: folderPath, printer: printer, options: options)
        case .remove(let arguments):
            return RemoveTask(arguments: arguments, rootFolderPath: folderPath, printer: printer, options: options)
        case .run(let arguments):
            return RunTask(arguments: arguments, rootFolderPath: folderPath, printer: printer)
        case .install(let arguments):
            return InstallTask(arguments: arguments, rootFolderPath: folderPath, printer: printer, options: options)
        case .add(let arguments):
            return AddTask(arguments: arguments, rootFolderPath: folderPath, printer: printer, options: options)
        case .list:
            return ListTask(rootFolderPath: folderPath, printer: printer)
        case .update:
            return UpdateTask(rootFolderPath: folderPath, printer: printer)
        case .help:
            return nil
        }
    }
    
    var allowsProgressOutput: Bool {
        if case .run(_) = self {
            return false
        }
        return true
    }
    
    var helpfulFeedback: String {
        let title = welcomeTitle
        let message = helpMessage
        var feedback = title + "\n" + title.dashesWithMatchingLength
        if case .help = self {
            feedback.append("-\n")
            feedback.append(message)
        } else {
            feedback.append("\n" + description + "\n\n")
            feedback.append("👉  Usage: 'marathon \(rawValue)")
            
            if !usageText.isEmpty {
                feedback.append(" \(usageText)")
            }
            
            feedback.append("'")
            
            if !message.isEmpty {
                feedback.append("\n\n" + message.withIndentedNewLines(prefix: "ℹ️  "))
            }
        }
        return feedback
    }
    
    private var welcomeTitle: String {
        guard self != .help else {
            return "Welcome to Marathon 🏃"
        }
        return makeTitle()
    }
    
    private var welcomeMessage: String {
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
    
    private var helpMessage: String {
        switch self {
        case .create, .edit:
            return "The script will be opened for editing in Xcode by default\n" +
                "To open the source file directly (without an Xcode project), pass the '--no-xcode' flag\n" +
            "To not open the script at all, pass the '--no-open' flag"
        case .remove:
            return "You can use this command to clean up data for scripts or packages no longer needed. To list them, use 'marathon list'\n" +
                "To remove all script data, pass the '--all-script-data' flag\n" +
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
            return welcomeMessage
        }
    }
    
    private var usageText: String {
        switch self {
        case .create:
            return "<script-name> [<script-content>] [--no-xcode] [--no-open]"
        case .edit:
            return "<script-name> [--no-xcode] [--no-open]"
        case .remove:
            return "<name-of-package-or-path-to-script> [--all-script-data] [--all-packages]"
        case .run:
            return "<script-name> [<script-arguments...>]"
        case .install:
            return "<script-name-or-url> [<install-path>] [--force]"
        case .add:
            return "<url-or-path-to-package>"
        case .list:
            return ""
        case .update:
            return ""
        case .help:
            return ""
        }
    }
    
    private func makeTitle(withPadding addPadding: Bool = false) -> String {
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
}
