/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import Files

public final class Marathon<Base> {
    let base: Base
    public init(_ base: Base) {
        self.base = base
    }
}

public protocol MarathonCompatible {
    associatedtype CompatibleType
    var mt: CompatibleType { get }
}

public extension MarathonCompatible {
    public var mt: Marathon<Self> {
        return Marathon(self)
    }
}

extension String: MarathonCompatible { }
extension URL: MarathonCompatible { }
extension Folder: MarathonCompatible { }
