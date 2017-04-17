/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files
import ShellOut

internal extension Folder {
    @discardableResult func moveToAndPerform(command: String) throws -> String {
        return try shellOut(to: command, at: path)
    }
}
