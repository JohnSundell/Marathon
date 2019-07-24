/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal final class UpdateTask: Task, Executable {
    func execute() throws {
        try packageManager.updateAllPackagesToLatestMajorVersion()
        printer.output("♻️  All packages updated")
    }
}
