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
                                          in folder: Folder = Folder.current,
                                          output: Printer) throws -> String {
    do {
        output.debug("$ cd \"\(folder.path)\" && \(command)")
        let feedback = try shellOut(to: command, at: folder.path)
        output.debug(feedback)

        return feedback
    } catch {
        let error = (error as? ShellOutError).require()

        if !error.output.isEmpty {
            output.debug(error.output)
        }

        output.debug(error.message)

        throw error
    }
}

@discardableResult internal func shellOutToSwiftCommand(_ command: String,
                                                        in folder: Folder = Folder.current,
                                                        output: Printer) throws -> String {
    func resolveSwiftPath() -> String {
        #if os(Linux)
        return "swift"
        #else
        return "/usr/bin/env xcrun --sdk macosx swift"
        #endif
    }

    let swiftPath = resolveSwiftPath()
    return try shellOut(to: "\(swiftPath) \(command)", in: folder, output: output)
}
