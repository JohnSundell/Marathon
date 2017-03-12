/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

@discardableResult internal func perform<T>(_ expression: @autoclosure () throws -> T, orThrow errorExpression: @autoclosure () -> Error) throws -> T {
    do {
        return try expression()
    } catch {
        throw errorExpression()
    }
}
