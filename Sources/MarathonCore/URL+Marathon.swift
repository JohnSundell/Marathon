/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal extension URL {
    var isForRemoteRepository: Bool {
        return absoluteString.hasSuffix(".git")
    }
}
