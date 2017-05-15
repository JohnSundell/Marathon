/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import MarathonCore
import Require

do {
    try MarathonCore.run()
} catch {
    let errorData = "\(error)".data(using: .utf8).require()
    FileHandle.standardError.write(errorData)
    exit(1)
}
