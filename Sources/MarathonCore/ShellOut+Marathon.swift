/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import ShellOut
import Require

@discardableResult internal func shellOut(to command: String,
                                          in folder: Folder = FileSystem().currentFolder,
                                          printer: Printer) throws -> String {
    do {
        printer.verboseOutput("$ cd \"\(folder.path)\" && \(command)")
        let output = try shellOut(to: command, at: folder.path)
        printer.verboseOutput(output)

        return output
    } catch {
        let error = (error as? ShellOutError).require()

        if !error.output.isEmpty {
            printer.verboseOutput(error.output)
        }

        printer.verboseOutput(error.message)

        throw error
    }
}
