/**
 *  Assert
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import XCTest

/**
 *  Assert that an expression throws a given error
 *
 *  Usage: `assert(try myFunction(), throwsError: MyError.anError)`
 *
 *  - parameter file: The file in which the assert should take place (automatically inferred)
 *  - parameter line: The line number at which the assert should take place (automatically inferred)
 *  - parameter expression: The expression that should throw an error
 *  - parameter errorExpression: An expression resulting in an error that is expected to be thrown
 */
public func assert<T, E: Error>(at file: StaticString = #file,
                                line: UInt = #line,
                                _ expression: @autoclosure () throws -> T,
                                throwsError errorExpression: @autoclosure () -> E) where E: Equatable {
    do {
        _ = try expression()
        XCTFail("Expected expression to throw", file: file, line: line)
    } catch let thrownError as E {
        let expectedError = errorExpression()

        XCTAssert(thrownError == expectedError,
                  "Incorrect error thrown. \(thrownError) is not equal to \(expectedError)",
            file: file,
            line: line)
    } catch {
        XCTFail("Invalid error thrown: \(error)", file: file, line: line)
    }
}

/**
 *  Assert that a closure throws a given error
 *
 *  Usage: `assertErrorThrown(MyError.anError) { try myFunction() }`
 *
 *  - parameter file: The file in which the assert should take place (automatically inferred)
 *  - parameter line: The line number at which the assert should take place (automatically inferred)
 *  - parameter errorExpression: An expression resulting in an error that is expected to be thrown
 *  - closure: The closure that should thrown an error
 */
public func assertErrorThrown<T, E: Error>(at file: StaticString = #file,
                                           line: UInt = #line,
                                           _ errorExpression: @autoclosure () -> E,
                                           by closure: () throws -> T) where E: Equatable {
    assert(at: file, line: line, try closure(), throwsError: errorExpression)
}

/**
 *  Assert that no error was thrown when executing a closure
 *
 *  Usage: `assertNoErrorThrown { try myFunction() }`
 *
 *  - parameter file: The file in which the assert should take place (automatically inferred)
 *  - parameter line: The line number at which the assert should take place (automatically inferred)
 *  - parameter closure: The closure that shouldn't throw an error
 */
public func assertNoErrorThrown<T>(at file: StaticString = #file, line: UInt = #line, from closure: () throws -> T) {
    do {
        _ = try closure()
    } catch {
        XCTFail("Error thrown: \(error)", file: file, line: line)
    }
}
