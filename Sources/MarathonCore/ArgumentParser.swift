//
//  ArgumentParser.swift
//  Marathon
//
//  Created by pixyzehn on 2017/04/09.
//
//

import Foundation

public struct ArgumentParser: CustomStringConvertible {
    private var arguments: [ArgumentType]

    private enum ArgumentType: CustomStringConvertible {
        case argument(String)
        case option(String)
        case flag(Character)

        var description: String {
            switch self {
            case .argument(let value):
                return value
            case .option(let option):
                return "--\(option)"
            case .flag(let flag):
                return "-\(String(flag))"
            }
        }
    }

    // MARK: - Init

    public init(arguments: [String]) {
        self.arguments = arguments.map { argument in
            if argument.characters.first == "-" {
                let flags = argument[argument.characters.index(after: argument.startIndex)..<argument.endIndex]

                if flags.characters.first == "-" {
                    let option = flags[flags.characters.index(after: flags.startIndex)..<flags.endIndex]
                    return .option(option)
                }

                if let flag = flags.characters.first, flags.characters.count == 1 {
                    return .flag(flag)
                }
            }

            return .argument(argument)
        }
    }

    // MARK: - API

    public var description:String {
        return arguments.map { $0.description }.joined(separator: " ")
    }

    public var isEmpty: Bool {
        return arguments.isEmpty
    }

    public func hasOption(_ optionName: String, flag flagName: Character = " ") -> Bool {
        for argument in arguments {
            switch argument {
            case .option(let option):
                if option == optionName {
                    return true
                }
            case .flag(let flag):
                if flag == flagName {
                    return true
                }
            default:
                break
            }
        }

        return false
    }
}
