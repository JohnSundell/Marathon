/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public final class Marathon {
    
    public enum Error: Swift.Error {
        case couldNotPerformSetup(String)
    }
    
    public static func run(with arguments: [String] = CommandLine.arguments, folderPath: String = "~/.marathon", printFunction: @escaping Printer.PrintFunction = { print($0) }) throws {
        try installShellAutocompleteIfNeeded(rootPath: folderPath)
        let request = try Request(printFunction: printFunction, arguments: arguments)
        try request.execute(folderPath)
    }
    
    private static func installShellAutocompleteIfNeeded(rootPath: String) throws {
        do {
            let autocompletionsFolder = try Locations.autocompletions.folder(rootPath: rootPath)
            ZshAutocompleteInstaller.installIfNeeded(in: autocompletionsFolder)
            FishAutocompleteInstaller.installIfNeeded(in: autocompletionsFolder)
        } catch {
            throw Error.couldNotPerformSetup(rootPath)
        }
        
    }
}
