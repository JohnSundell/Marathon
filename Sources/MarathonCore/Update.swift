/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

final class UpdateTask: Task, Executable {
    
    func execute() throws {
        let packageManager = try PackageManager.assemble(with: rootPath, using: output)
        try packageManager.updateAllPackagesToLatestMajorVersion()
        output.conclusion("♻️  All packages updated")
    }
}
