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

internal enum Command: String {
    case create
    case edit
    case remove
    case run
    case install
    case add
    case list
    case update
    case help
}

extension Command {
    private typealias Error = CommandError

    static var all: [Command] {
        return [.create, .edit, .remove, .run, .install, .add, .list, .update, .help]
    }

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

    var usageText: String {
        switch self {
        case .create:
            return "<script-path> [<script-content>] [--no-xcode] [--no-open]"
        case .edit:
            return "<script-path> [--no-xcode] [--no-open]"
        case .remove:
            return "<name-of-package-or-path-to-script> [--all-script-data] [--all-packages]"
        case .run:
            return "<script-path> [<script-arguments...>]"
        case .install:
            return "<script-path-or-url> [<install-path>] [--force]"
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

    var makeTaskClosure: (Folder, [String], ScriptManager, PackageManager, Printer) -> Executable {
        switch self {
        case .create:
            return CreateTask.init
        case .add:
            return AddTask.init
        case .edit:
            return EditTask.init
        case .remove:
            return RemoveTask.init
        case .run:
            return RunTask.init
        case .install:
            return InstallTask.init
        case .list:
            return ListTask.init
        case .update:
            return UpdateTask.init
        case .help:
            return HelpTask.init
        }
    }

    var allowsProgressOutput: Bool {
        return self != .run
    }

    init(arguments: [String], index: Int = 1) throws {
        guard let commandString = arguments.element(at: index) else {
            self = .help
            return
        }

        guard let command = Command(rawValue: commandString) else {
            throw Error.invalid(commandString)
        }

        self = command
    }
}
