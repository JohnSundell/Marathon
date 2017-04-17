/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

internal extension Folder {
    @discardableResult func moveToAndPerform(command: String, printer: Printer) throws -> String {
        return try shellOut(to: command, in: self, printer: printer)
    }
}

internal extension Folder {
    func createSymlink(to originalPath: String, at linkPath: String, printer: Printer) throws {
        try shellOut(to: "ln -s \"\(originalPath)\" \"\(linkPath)\"", in: self, printer: printer)
    }
}
