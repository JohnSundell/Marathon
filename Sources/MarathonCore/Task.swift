/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

class Task {
    let rootPath: String
    let output: Printer
    
    init(rootFolderPath: String, printer: Printer) {
        self.rootPath = rootFolderPath
        self.output = printer
    }
}
