/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Releases
import Unbox

extension Version: UnboxableByTransform {
    public typealias UnboxRawValue = String

    public static func transform(unboxedValue: String) -> Version? {
        return try? Version(string: unboxedValue)
    }
}
