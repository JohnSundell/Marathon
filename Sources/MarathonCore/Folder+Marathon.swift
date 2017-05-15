/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

internal extension Marathon where Base == Folder {
    @discardableResult func moveToAndPerform(command: String, printer: Printer) throws -> String {
        return try shellOut(to: command, in: base.self, printer: printer)
    }

    func createSymlink(to originalPath: String, at linkPath: String, printer: Printer) throws {
        try shellOut(to: "ln -s \"\(originalPath)\" \"\(linkPath)\"", in: base.self, printer: printer)
    }
}
