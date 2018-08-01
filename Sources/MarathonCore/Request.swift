//
//  Request.swift
//  MarathonCore
//
//  Created by Robert Nash on 31/07/2018.
//

import Foundation

struct Request {
    
    let command: Command
    let printer: Printer
    let options: [Option]
    
    init(printFunction: @escaping Printer.PrintFunction, arguments: [String]) throws {
        var arguments = arguments
        arguments.removeFirst()
        self.options = Option.assemble(from: &arguments)
        if let argument = arguments.first {
            self.command = try Command(command: argument, arguments: Array(arguments.dropFirst()))
        } else {
            self.command = .help
        }
        let allowsProgressOutput = self.command.allowsProgressOutput
        let allowVerboseOutput = self.options.contains(.verbose)
        self.printer = Printer(printFunction, self.options, allowsProgressOutput, allowVerboseOutput)
    }
    
    func execute(_ folderPath: String) throws {
        if let task = command.makeExecutable(folderPath, printer, options) {
            try task.execute()
        } else {
            printer.conclusion(command.helpfulFeedback)
        }
    }
}
