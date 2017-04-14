/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import MarathonCore
import Files

internal extension Folder {
    @discardableResult func moveToAndPerform(command: String) throws -> String {
        let printer = Printer(
            outputFunction: { _ in },
            progressFunction: { (_: () -> String) in },
            verboseFunction: { (_: () -> String) in }
        )

        return try moveToAndPerform(command: command, printer: printer)
    }
}
