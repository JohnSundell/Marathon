//
//  Option.swift
//  MarathonCore
//
//  Created by Robert Nash on 29/07/2018.
//

import Foundation
import Require

/// Options passed in by the user, as arguments.
///
/// - noOpen: Prevent the script from launching in an editor.
/// - force: Overwrite any existing binary when installing.
/// - allScriptData: When removing a script also remove all associated script data.
/// - allPackages: When removing a script also remove all associated script packages.
/// - verbose: Provide detailed output.
/// - noXcode: Prevent the generation of and Xcode project file.
enum Option: String {
    
    case noOpen = "--no-open"
    case force = "--force"
    case allScriptData = "--all-script-data"
    case allPackages = "--all-packages"
    case verbose = "--verbose"
    case noXcode = "--no-xcode"
    
    /// Parse user-supplied arguments.
    ///
    /// - Parameter arguments: Options supplied by the user as command line arguments. Any parsed values are removed.
    /// - Returns: A collection of parsed options, as options.
    static func assemble(from arguments: inout [String]) -> [Option] {
        let options: [Option] = [.noOpen, .force, .allScriptData, .allPackages, .verbose, .noXcode]
        return options.filter { option in
            let index = arguments.index(where: { (argument) -> Bool in
                return argument == option.rawValue
            })
            switch index {
            case .some(let position):
                arguments.remove(at: position)
                return true
            case .none:
                return false
            }
        }
    }
}
