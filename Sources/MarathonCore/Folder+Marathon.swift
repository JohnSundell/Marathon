/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

internal extension Folder {
    @discardableResult func moveToAndPerform(command: String, output: Printer) throws -> String {
        return try shellOut(to: command, in: self, output: output)
    }
}

internal extension Folder {
    func createSymlink(to originalPath: String, at linkPath: String, output: Printer) throws {
        try shellOut(to: "ln -s \"\(originalPath)\" \"\(linkPath)\"", in: self, output: output)
    }
}
