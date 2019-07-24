/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

public class Task {
    let folder: Folder
    let arguments: [String]
    let scriptManager: ScriptManager
    let packageManager: PackageManager
    let printer: Printer

    init(folder: Folder,
         arguments: [String],
         scriptManager: ScriptManager,
         packageManager: PackageManager,
         printer: Printer) {
        self.folder = folder
        self.arguments = arguments
        self.scriptManager = scriptManager
        self.packageManager = packageManager
        self.printer = printer
    }
}

extension Task {
    var argumentsContainNoOpenFlag: Bool {
        return arguments.contains("--no-open")
    }
}
