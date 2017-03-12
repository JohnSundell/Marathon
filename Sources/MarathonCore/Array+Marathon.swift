/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

internal extension Array {
    func element(at index: Int) -> Element? {
        guard index < count else {
            return nil
        }

        return self[index]
    }
}
