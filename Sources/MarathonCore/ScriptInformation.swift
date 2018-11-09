/**
 *  Marathon
 *  Copyright (c) John Sundell 2017
 *  Licensed under the MIT license. See LICENSE file.
 */

import Foundation

public struct ScriptInformation {
    var minMacosVersion: String
}

enum ScriptInformationKeys: String {
    case minMacosVersion = "min-macos-version"
}

