/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import MarathonCore
import Require

do {
    try Marathon.run()
} catch {
    let errorData = "\(error)\n".data(using: .utf8).require()
    FileHandle.standardError.write(errorData)
    exit(1)
}
