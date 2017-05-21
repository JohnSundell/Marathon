/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

internal final class ZshAutocompleteInstaller {
    static func installIfNeeded(in folder: Folder) {
        do {
            guard !folder.containsSubfolder(named: "zsh") else {
                return
            }

            let zshFolder = try folder.createSubfolder(named: "zsh")
            let autocompleteFile = try zshFolder.createFile(named: "_marathon")

            var autocompleteCode = "#compdef marathon\n\n"
            autocompleteCode.append("local -a commands\n\n")
            autocompleteCode.append("commands=(")

            for command in Command.all {
                autocompleteCode.append("\n    \"\(command.rawValue):\(command.description)\"")
            }

            autocompleteCode.append("\n)\n\n")
            autocompleteCode.append("_arguments \\\n")
            autocompleteCode.append("    \"1: :{_describe 'command' commands}\" \\\n")
            autocompleteCode.append("    \"*: filename:_files\"")

            try autocompleteFile.write(string: autocompleteCode)
        } catch {
            // Since this operation isn't critical, we silently fail if an error occur
        }
    }
}
