/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

// MARK: - Typealiases

public typealias PrintFunction = (String) -> Void
public typealias VerbosePrintFunction = (@autoclosure () -> String) -> Void

// MARK: - Printer

public class Printer {
    internal let output: PrintFunction
    internal let reportProgress: VerbosePrintFunction
    internal let verboseOutput: VerbosePrintFunction

    public init(outputFunction: @escaping PrintFunction,
                progressFunction: @escaping VerbosePrintFunction,
                verboseFunction: @escaping VerbosePrintFunction) {
        output = outputFunction
        reportProgress = progressFunction
        verboseOutput = verboseFunction
    }
}
