/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public struct ScriptInformation {
    var minMacosVersion: String
}

extension ScriptInformation {
    static var `default`: ScriptInformation {
        return ScriptInformation(
            minMacosVersion: "10.9"
        )
    }
}

enum ScriptInformationKeys: String {
    case minMacosVersion = "min-macos-version"
}

