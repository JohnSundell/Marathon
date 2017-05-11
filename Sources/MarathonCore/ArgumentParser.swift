//
//  ArgumentParser.swift
//  Marathon
//
//  Created by pixyzehn on 2017/04/09.
//
//

import Foundation

public struct ArgumentParser {
    fileprivate var options: [Option]

    fileprivate struct Option {
        let long: String
        let short: String
    }

    // MARK: - Init

    public init(arguments: [String]) {
        self.options = arguments.filter { argument in
            return argument.hasPrefix("-") || argument.hasPrefix("--") || !argument.hasPrefix("---")
        }.map { argument in
            if argument.hasPrefix("--") {
                return Option(long: argument, short: "")
            } else {
                return Option(long: "", short: argument)
            }
        }
    }

    // MARK: - API

    public var isEmpty: Bool {
        return options.isEmpty
    }

    public func hasOption(_ long: String, short: String) -> Bool {
        let option = Option(long: long, short: short)
        if options.contains(option) {
            return true
        }
        return false
    }
}

// MARK: - Private utilities

private extension Array where Element == ArgumentParser.Option {
    func contains(_ option: ArgumentParser.Option) -> Bool {
        for element in self {
            if element.long == option.long || element.short == option.short {
                return true
            }
        }
        return false
    }
}
