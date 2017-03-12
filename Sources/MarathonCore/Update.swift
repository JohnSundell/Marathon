/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal final class UpdateTask: Task, Executable {
    func execute() throws -> String {
        try packageManager.updateAllPackagesToLatestMajorVersion()
        return "♻️  All packages updated"
    }
}
