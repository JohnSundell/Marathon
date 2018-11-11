/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation
import ShellOut

// MARK: - Error

public enum ScriptInformationError {
    case invalidFormat(String, String)
    case wrongKey(String, [String])
}

extension ScriptInformationError: PrintableError {
    public var message: String {
        switch self {
        case let .invalidFormat(information, _):
            return "Could not process the inline information: '\(information)'"
        case let .wrongKey(key, _):
            return "The key '\(key)' is not valid"
        }
    }
    
    public var hints: [String] {
        switch self {
        case let .invalidFormat(_, separator):
            return ["Please verify that the inline information provided follows the format <key>\(separator)<value>"]
        case let .wrongKey(_, availableKeys):
            return ["The available keys are: \(availableKeys.joined(separator: ", "))"]
        }
    }
}

public typealias ScriptInformation = [ScriptInformationKey: String]

public extension Dictionary where Key == ScriptInformation.Key, Value == ScriptInformation.Value {
    private typealias Error = ScriptInformationError

    static func resolve(from line: String, separator: String) throws -> ScriptInformation.Element {
        let components = line.components(separatedBy: separator)
        
        guard components.count == 2 else {
            throw Error.invalidFormat(line, separator)
        }
        
        let keyString = components[0].trimmingCharacters(in: .whitespaces)
        guard let informationKey = ScriptInformationKey(rawValue: keyString) else {
            throw Error.wrongKey(keyString, ["TODO: pass the keys here when updated to swift 4.2"]) // TODO: print all the possible keys for inline information when updated to swift 4.2
        }
        
        let valueString = components[1].trimmingCharacters(in: .whitespaces)
        switch informationKey {
        case .minDeploymentTarget: return (key: .minDeploymentTarget, value: valueString)
        }
    }
    
    func getValue(forKey key: Key) -> Value {
        return self[key] ?? key.defaultValue
    }
}

public enum ScriptInformationKey: String {
    case minDeploymentTarget = "min-deployment-target"
    
    var defaultValue: String {
        switch self {
        case .minDeploymentTarget:
            #if os(Linux)
            return "x86_64-unknown-linux-gnu" // This should be the default target when runnning in linux
            #else
            let systemVersion = try? shellOut(to: "sw_vers -productVersion")
            return "x86_64-apple-macosx" + (systemVersion ?? "10.9")
            #endif
        }
    }
}

