/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

internal final class FishAutocompleteInstaller {
    static func installIfNeeded(in folder: Folder) {
        do {
            guard !folder.containsSubfolder(named: "fish") else {
                return
            }

            let zshFolder = try folder.createSubfolder(named: "fish")
            let autocompleteFile = try zshFolder.createFile(named: "marathon.fish")

            var autocompleteCode = generateFishFunctions()

            for command in Command.all {
                autocompleteCode.append("complete -f -c marathon " +
                        "-n '__fish_marathon_needs_command' " +
                        "-a '\(command.rawValue)' " +
                        "-d '\(command.description)'" +
                        "\n")
            }

            try autocompleteFile.write(string: autocompleteCode)
        } catch {
            // Since this operation isn't critical, we silently fail if an error occur
        }
    }

    fileprivate static func generateFishFunctions() -> String {
        let needsCommand =  "function __fish_marathon_needs_command\n" +
                            "\tset cmd (commandline -opc)\n" +
                            "\tif [ (count $cmd) -eq 1 ]\n" +
                            "\t\treturn 0\n" +
                            "\tend\n" +
                            "\treturn 1\n" +
                            "end" +
                            "\n\n"

        return needsCommand
    }
}
