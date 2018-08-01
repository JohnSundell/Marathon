/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public final class Printer {
    
    public typealias PrintFunction = (String) -> Void
    public typealias VerbosePrintFunction = (@autoclosure () -> String) -> Void
    
    let conclusion: PrintFunction
    let progress: VerbosePrintFunction
    let debug: VerbosePrintFunction
    
    public init(conclusion: @escaping PrintFunction,
                progress: @escaping VerbosePrintFunction,
                debug: @escaping VerbosePrintFunction) {
        self.conclusion = conclusion
        self.progress = progress
        self.debug = debug
    }
    
    convenience init(_ printFunction: @escaping PrintFunction, _ options: [Option], _ allowsProgressOutput: Bool, _ allowsVerboseOutput: Bool) {
        var isFirstOutput = true
        let progress: Printer.VerbosePrintFunction = { (messageExpression: () -> String) in
            guard allowsProgressOutput || allowsVerboseOutput else {
                return
            }
            
            let message = messageExpression()
            printFunction(message.withIndentedNewLines(prefix: isFirstOutput ? "🏃  " : "   "))
            
            isFirstOutput = false
        }
        let debug: Printer.VerbosePrintFunction = { (messageExpression: () -> String) in
            guard allowsProgressOutput else {
                return
            }
            
            // Make text italic
            let message = "\u{001B}[0;3m\(messageExpression())\u{001B}[0;23m"
            printFunction(message)
        }
        self.init(conclusion: printFunction, progress: progress, debug: debug)
    }
}
