/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

public extension Folder {
    @discardableResult func moveToAndPerform(command: String) throws -> String {
        return try Process().launchBash(withCommand: "cd \(path) && \(command)")
    }
}

internal extension Folder {
    func createSymlink(to originalPath: String, at linkPath: String) throws {
        try moveToAndPerform(command: "ln -s \(originalPath) \(linkPath)")
    }
}
